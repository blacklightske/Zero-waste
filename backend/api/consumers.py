"""
WebSocket consumers for real-time chat and notifications
"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import Message, WasteProduct

User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    """WebSocket consumer for product-specific chat"""
    
    async def connect(self):
        self.product_id = self.scope['url_route']['kwargs']['product_id']
        self.room_group_name = f'chat_{self.product_id}'
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
    
    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        """Receive message from WebSocket"""
        try:
            text_data_json = json.loads(text_data)
            message_content = text_data_json['message']
            sender_id = text_data_json['sender_id']
            receiver_id = text_data_json['receiver_id']
            
            # Save message to database
            message = await self.save_message(
                self.product_id, 
                sender_id, 
                receiver_id, 
                message_content
            )
            
            # Send message to room group
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': {
                        'id': str(message.id),
                        'content': message.content,
                        'sender_id': str(message.sender.id),
                        'sender_name': message.sender.get_full_name() or message.sender.username,
                        'timestamp': message.timestamp.isoformat(),
                        'product_id': str(message.product.id),
                    }
                }
            )
        except Exception as e:
            await self.send(text_data=json.dumps({
                'error': f'Error processing message: {str(e)}'
            }))
    
    async def chat_message(self, event):
        """Receive message from room group"""
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': event['message']
        }))
    
    @database_sync_to_async
    def save_message(self, product_id, sender_id, receiver_id, content):
        """Save message to database"""
        try:
            product = WasteProduct.objects.get(id=product_id)
            sender = User.objects.get(id=sender_id)
            receiver = User.objects.get(id=receiver_id)
            
            message = Message.objects.create(
                product=product,
                sender=sender,
                receiver=receiver,
                content=content
            )
            return message
        except Exception as e:
            raise Exception(f"Failed to save message: {str(e)}")


class NotificationConsumer(AsyncWebsocketConsumer):
    """WebSocket consumer for user notifications"""
    
    async def connect(self):
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.notification_group_name = f'notifications_{self.user_id}'
        
        # Join notification group
        await self.channel_layer.group_add(
            self.notification_group_name,
            self.channel_name
        )
        
        await self.accept()
    
    async def disconnect(self, close_code):
        # Leave notification group
        await self.channel_layer.group_discard(
            self.notification_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        """Handle incoming notification requests"""
        try:
            data = json.loads(text_data)
            if data.get('type') == 'mark_read':
                notification_id = data.get('notification_id')
                await self.mark_notification_read(notification_id)
        except Exception as e:
            await self.send(text_data=json.dumps({
                'error': f'Error processing notification: {str(e)}'
            }))
    
    async def notification_message(self, event):
        """Send notification to user"""
        await self.send(text_data=json.dumps({
            'type': 'notification',
            'notification': event['notification']
        }))
    
    @database_sync_to_async
    def mark_notification_read(self, notification_id):
        """Mark notification as read"""
        # This would be implemented with a Notification model
        # For now, we'll just pass
        pass


# Utility function to send notifications
async def send_notification_to_user(user_id, notification_data):
    """Send a notification to a specific user"""
    from channels.layers import get_channel_layer
    
    channel_layer = get_channel_layer()
    notification_group_name = f'notifications_{user_id}'
    
    await channel_layer.group_send(
        notification_group_name,
        {
            'type': 'notification_message',
            'notification': notification_data
        }
    )
