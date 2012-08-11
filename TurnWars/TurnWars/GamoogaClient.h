#define GAMOOGA_CLIENT_SERVER_BUSY 3
#define GAMOOGA_CLIENT_SERVER_ERROR 4
#define GAMOOGA_CLIENT_IN_DATA_EXCEED 6
#define GAMOOGA_CLIENT_OUT_DATA_EXCEED 7
#define GAMOOGA_CLIENT_IO_ERROR 101
#define GAMOOGA_CLIENT_SECURITY_ERROR 102
#define GAMOOGA_CLIENT_WEBSOCKET_ERROR 103
#define GAMOOGA_CLIENT_WRONG_APP_ID 201
#define GAMOOGA_CLIENT_WRONG_APP_UUID 202
#define GAMOOGA_CLIENT_APP_ID_AND_UUID_NOT_PROVIDED 203
#define GAMOOGA_CLIENT_LIMITS_REACHED 204
#define GAMOOGA_CLIENT_GAMLET_UNDEPLOYED 205
#define GAMOOGA_CLIENT_API_ERROR 301

#ifndef GAMOOGA_CLIENT_PRIVATE_VARS
#define GAMOOGA_CLIENT_PRIVATE_VARS
#endif

@interface GamoogaClient: NSObject <NSStreamDelegate> {
@private
	GAMOOGA_CLIENT_PRIVATE_VARS
}

- (GamoogaClient *) init;
- (GamoogaClient *) initWithDevServer: (NSString *) devServer;
- (GamoogaClient *) initWithDevServer: (NSString *) devServer andGmgPort: (int) gPort andApiPort: (int) aPort;
- (void) connectToRoomWithAppId:(int)appId andAppUuid:(NSString*) appUuid;
- (void) createConnectToSessionWithAppId:(int)appId andAppUuid:(NSString*) appUuid;
- (void) connectToSessionWithSessId:(int)sessId andAppUuid:(NSString*) appUuid;
- (void) sendMessage:(id)msg withType:(NSString *)type;
- (void) disconnect;
- (void) disableLogMsg;
- (void) enableLogMsg;
- (void) onConnectCallback:(SEL)selector withTarget:(id)object;
- (void) onMessageCallback:(SEL)selector withTarget:(id)object forType:(NSString *)type;
- (void) onDisconnectCallback:(SEL)selector withTarget:(id)object;
- (void) onErrorCallback:(SEL)selector withTarget:(id)object;
@end
