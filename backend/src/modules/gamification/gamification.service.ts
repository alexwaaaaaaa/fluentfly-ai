import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { Badge } from './entities/badge.entity';
import { UserBadge } from './entities/user-badge.entity';
import { RedisService } from '../../common/redis/redis.service';
import { XpResponse } from './dto/xp-response.dto';
import { StreakResponse } from './dto/streak-response.dto';
import { LeaderboardEntry } from './dto/leaderboard-entry.dto';

@Injectable()
export class GamificationService {
  private readonly logger = new Logger(GamificationService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Badge)
    private readonly badgeRepository: Repository<Badge>,
    @InjectRepository(UserBadge)
    private readonly userBadgeRepository: Repository<UserBadge>,
    private readonly redisService: RedisService,
  ) {}

  /**
   * Award XP to a user with streak bonuses and check for level ups and badges
   */
  async awardXp(
    userId: number,
    amount: number,
    reason: string,
  ): Promise<XpResponse> {
    this.logger.log(`Awarding ${amount} XP to user ${userId} for ${reason}`);

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found');
    }

    // Calculate bonus XP from streak
    let bonusXp = 0;
    if (user.streak > 0) {
      bonusXp = user.streak * 5; // 5 XP per streak day
    }

    const totalXp = amount + bonusXp;
    const previousLevel = user.level;

    // Update user XP
    user.xp += totalXp;

    // Check for level up
    const newLevel = this.calculateLevel(user.xp);
    const leveledUp = newLevel !== previousLevel;

    if (leveledUp) {
      user.level = newLevel;
      this.logger.log(`User ${userId} leveled up to ${newLevel}`);
    }

    await this.userRepository.save(user);

    // Check for new badges
    const newBadges = await this.checkAndAwardBadges(user);

    // Invalidate leaderboard cache
    await this.redisService.del('leaderboard:*');

    return {
      xpAwarded: totalXp,
      totalXp: user.xp,
      leveledUp,
      newLevel: user.level,
      newBadges: newBadges.map((badge) => ({
        id: badge.id,
        name: badge.name,
        description: badge.description || '',
      })),
    };
  }

  /**
   * Calculate user level based on total XP
   * Level thresholds: A1: 0-99, A2: 100-299, B1: 300-599, B2: 600-999, C1: 1000-1499, C2: 1500+
   */
  calculateLevel(xp: number): string {
    if (xp >= 1500) return 'C2';
    if (xp >= 1000) return 'C1';
    if (xp >= 600) return 'B2';
    if (xp >= 300) return 'B1';
    if (xp >= 100) return 'A2';
    return 'A1';
  }

  /**
   * Check and award badges based on user achievements
   */
  async checkAndAwardBadges(user: User): Promise<Badge[]> {
    const allBadges = await this.badgeRepository.find();
    const userBadges = await this.userBadgeRepository.find({
      where: { userId: user.id },
    });
    const earnedBadgeIds = new Set(userBadges.map((ub) => ub.badgeId));
    const newBadges: Badge[] = [];

    for (const badge of allBadges) {
      // Skip if already earned
      if (earnedBadgeIds.has(badge.id)) {
        continue;
      }

      // Check badge criteria
      const earned = await this.checkBadgeCriteria(user, badge);
      if (earned) {
        // Award badge
        const userBadge = this.userBadgeRepository.create({
          userId: user.id,
          badgeId: badge.id,
        });
        await this.userBadgeRepository.save(userBadge);
        newBadges.push(badge);
        this.logger.log(`User ${user.id} earned badge: ${badge.name}`);
      }
    }

    return newBadges;
  }

  /**
   * Check if user meets badge criteria
   */
  private async checkBadgeCriteria(user: User, badge: Badge): Promise<boolean> {
    if (!badge.criteria || !badge.criteria.type) {
      return false;
    }

    const { type, value } = badge.criteria;

    switch (type) {
      case 'streak':
        return user.streak >= value;
      
      case 'xp':
        return user.xp >= value;
      
      case 'lessons_completed':
        // Would need to query progress table
        // For now, return false as we don't have progress data here
        return false;
      
      case 'vocabulary_learned':
        // Would need to track vocabulary count
        return false;
      
      default:
        return false;
    }
  }

  /**
   * Check and update user streak
   */
  async checkStreak(userId: number): Promise<StreakResponse> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const lastActive = user.lastActiveDate ? new Date(user.lastActiveDate) : null;
    let streakIncremented = false;
    let bonusXp = 0;

    if (!lastActive) {
      // First time user is active
      user.streak = 1;
      user.lastActiveDate = today;
      streakIncremented = true;
    } else {
      const lastActiveDate = new Date(lastActive);
      lastActiveDate.setHours(0, 0, 0, 0);

      const daysDiff = Math.floor(
        (today.getTime() - lastActiveDate.getTime()) / (1000 * 60 * 60 * 24),
      );

      if (daysDiff === 0) {
        // Already active today, no change
        streakIncremented = false;
      } else if (daysDiff === 1) {
        // Consecutive day, increment streak
        user.streak += 1;
        user.lastActiveDate = today;
        streakIncremented = true;
        bonusXp = user.streak * 5;
      } else {
        // Streak broken, reset to 1
        user.streak = 1;
        user.lastActiveDate = today;
        streakIncremented = true;
      }
    }

    await this.userRepository.save(user);

    // Check for streak badges
    if (streakIncremented) {
      await this.checkAndAwardBadges(user);
    }

    return {
      streak: user.streak,
      streakIncremented,
      bonusXp,
    };
  }

  /**
   * Get leaderboard with pagination and caching
   */
  async getLeaderboard(
    page: number = 1,
    limit: number = 100,
  ): Promise<LeaderboardEntry[]> {
    const cacheKey = `leaderboard:${page}:${limit}`;

    // Try cache first
    const cached = await this.redisService.get<LeaderboardEntry[]>(cacheKey);
    if (cached) {
      this.logger.debug('Returning cached leaderboard');
      return cached;
    }

    // Fetch from database
    const skip = (page - 1) * limit;
    const users = await this.userRepository.find({
      order: { xp: 'DESC' },
      skip,
      take: limit,
    });

    const leaderboard: LeaderboardEntry[] = users.map((user, index) => ({
      rank: skip + index + 1,
      userId: user.id,
      name: user.name,
      xp: user.xp,
      level: user.level,
      streak: user.streak,
      profileImageUrl: user.profileImageUrl || null,
    }));

    // Cache for 1 minute
    await this.redisService.set(cacheKey, leaderboard, 60);

    return leaderboard;
  }

  /**
   * Get user badges
   */
  async getUserBadges(userId: number): Promise<Badge[]> {
    const userBadges = await this.userBadgeRepository.find({
      where: { userId },
      relations: ['badge'],
    });

    return userBadges.map((ub) => ub.badge);
  }
}
