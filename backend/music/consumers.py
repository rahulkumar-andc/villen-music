import json
from channels.generic.websocket import AsyncWebsocketConsumer

class SyncConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope["user"]
        
        if not self.user.is_authenticated:
            await self.close()
            return
            
        self.group_name = f"user_{self.user.id}"
        
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    # Receive message from WebSocket
    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type')
        
        if message_type == 'playback_state':
            # Broadcast to other devices
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'sync_playback',
                    'sender_channel_name': self.channel_name,
                    'data': data['payload']
                }
            )

    # Receive message from group
    async def sync_playback(self, event):
        # Don't send back to sender
        if self.channel_name == event.get('sender_channel_name'):
            return
            
        await self.send(text_data=json.dumps({
            'type': 'playback_state',
            'payload': event['data']
        }))
