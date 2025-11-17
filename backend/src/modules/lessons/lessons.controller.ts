import {
  Controller,
  Get,
  Param,
  Query,
  ParseIntPipe,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { LessonsService } from './lessons.service';
import { LessonQueryDto } from './dto/lesson-query.dto';
import { LessonResponseDto, ExerciseResponseDto } from './dto/lesson-response.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('lessons')
@Controller('lessons')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class LessonsController {
  constructor(private readonly lessonsService: LessonsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all lessons with optional filtering' })
  @ApiResponse({
    status: 200,
    description: 'Returns list of lessons',
    type: [LessonResponseDto],
  })
  async findAll(@Query() query: LessonQueryDto): Promise<LessonResponseDto[]> {
    return this.lessonsService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single lesson by ID' })
  @ApiParam({ name: 'id', description: 'Lesson ID' })
  @ApiResponse({
    status: 200,
    description: 'Returns lesson details',
    type: LessonResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Lesson not found',
  })
  async findOne(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<LessonResponseDto> {
    return this.lessonsService.findOneWithExercises(id);
  }

  @Get(':id/exercises')
  @ApiOperation({ summary: 'Get all exercises for a lesson' })
  @ApiParam({ name: 'id', description: 'Lesson ID' })
  @ApiResponse({
    status: 200,
    description: 'Returns list of exercises',
    type: [ExerciseResponseDto],
  })
  @ApiResponse({
    status: 404,
    description: 'Lesson not found',
  })
  async getExercises(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<ExerciseResponseDto[]> {
    return this.lessonsService.getExercises(id);
  }
}
