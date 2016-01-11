//
//  ViewController.m
//  WLXBluetoothDeviceExample
//
//  Created by Guido Marucci Blas on 1/7/16.
//  Copyright © 2016 Wolox. All rights reserved.
//

#import "ViewController.h"
#import <WLXBluetoothDevice/WLXBluetoothDevice.h>

@interface ViewController ()<WLXDeviceDiscovererDelegate>

@property (nonatomic) WLXBluetoothDeviceManager * bluetoothDeviceManager;
@property (nonatomic) id<WLXConnectionManager> connectionManager;
@property (nonatomic) id<WLXDeviceDiscoverer> discoverer;
@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) WLXBluetoothDeviceRegistry * registry;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.notificationCenter = [NSNotificationCenter defaultCenter];
    [self.notificationCenter addObserver:self selector:@selector(bluetoothEnabled:) name:WLXBluetoothDeviceBluetoothIsOn object:nil];
    self.bluetoothDeviceManager = [WLXBluetoothDeviceManager deviceManager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer startDiscoveringDevicesWithTimeout:(NSUInteger)timeout {
    NSLog(@"Start discovering devices");
}

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer discoveredDevice:(WLXDeviceDiscoveryData *)discoveryData {
    [self.discoverer stopDiscoveringDevices];
    [self connectToPeripheral:discoveryData.peripheral];
}

- (void)deviceDiscovererStopDiscoveringDevices:(id<WLXDeviceDiscoverer>)discoverer {
    NSLog(@"Stop discovering devices");
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral {
    id<WLXReconnectionStrategy> strategy = [[WLXNullReconnectionStrategy alloc] init];
    self.connectionManager = [self.bluetoothDeviceManager connectionManagerForPeripheral:peripheral
                                                               usingReconnectionStrategy:strategy];
    [self.connectionManager connectWithTimeout:10000 usingBlock:^(NSError * error) {
        if (error) {
            NSLog(@"Connection error %@", error);
        } else {
            NSLog(@"Connection established!");
        }
    }];
}

- (void)bluetoothEnabled:(NSNotification * )notification {
    [self.notificationCenter removeObserver:self name:WLXBluetoothDeviceBluetoothIsOn object:nil];
    
    id<WLXBluetoothDeviceRepository> repository = [[WLXBluetoothDeviceUserDefaultsRepository alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
    self.registry = [self.bluetoothDeviceManager deviceRegistryWithRepository:repository];
    self.registry.enabled = YES;
    
    
    [self.registry fetchLastConnectedPeripheralWithBlock:^(NSError *error, CBPeripheral *peripheral) {
        if (error) {
            NSLog(@"Error fetching the last connected peripheral!");
        }
            
        if (peripheral) {
            // Connect
            NSLog(@"Getting peripheral from local repository");
            [self connectToPeripheral:peripheral];
        } else {
            // Discover
            self.discoverer = self.bluetoothDeviceManager.discoverer;
            self.discoverer.delegate = self;
            BOOL discovering = [self.discoverer discoverDevicesNamed:@"Syrmo Tracker" withServices:nil andTimeout:30000];
            if (!discovering) {
                    NSLog(@"Cannot start the discovering process");
            }
        }
    }];
}

@end
