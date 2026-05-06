import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { CreateMessageDto } from './dto/create-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { User } from '../common/decorators/user.decorator';

@ApiTags('chat')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('conversations')
  @ApiOperation({ summary: 'Create a new conversation' })
  createConversation(
    @Body(ValidationPipe) dto: CreateConversationDto,
    @User() user: any,
  ) {
    // Support household members: use primaryUserId if available, else user's own id
    const residentId = user.primaryUserId ?? user.id;
    return this.chatService.createConversation(residentId, dto);
  }

  @Get('conversations')
  @ApiOperation({ summary: 'List resident conversations' })
  @ApiQuery({ name: 'skip', required: false })
  @ApiQuery({ name: 'take', required: false })
  getConversations(
    @User() user: any,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    const residentId = user.primaryUserId ?? user.id;
    return this.chatService.getConversations(residentId, skip ? +skip : 0, take ? +take : 20);
  }

  @Get('conversations/:id')
  @ApiOperation({ summary: 'Get conversation with messages' })
  getConversation(@User() user: any, @Param('id') id: string) {
    const residentId = user.primaryUserId ?? user.id;
    return this.chatService.getConversation(residentId, id);
  }

  @Post('conversations/:id/messages')
  @ApiOperation({ summary: 'Send a message as resident' })
  sendMessage(
    @User() user: any,
    @Param('id') id: string,
    @Body(ValidationPipe) dto: CreateMessageDto,
  ) {
    const residentId = user.primaryUserId ?? user.id;
    return this.chatService.sendMessage(residentId, id, dto);
  }

  @Patch('conversations/:id/read')
  @ApiOperation({ summary: 'Mark admin messages as read' })
  markRead(@User() user: any, @Param('id') id: string) {
    const residentId = user.primaryUserId ?? user.id;
    return this.chatService.markRead(residentId, id);
  }
}
