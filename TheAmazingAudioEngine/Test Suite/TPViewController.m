//
//  TPViewController.m
//  Audio Controller Test Suite
//
//  Created by Michael Tyson on 13/02/2012.
//  Copyright (c) 2012 A Tasty Pixel. All rights reserved.
//

#import "TPViewController.h"
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>
#import "TPOscilloscopeLayer.h"
#import "TPDoubleSpeedFilter.h"
#import "AEPlaythroughChannel.h"
#import "AEExpanderFilter.h"
#import "AELimiterFilter.h"
#import "AERecorder.h"
#import <QuartzCore/QuartzCore.h>

#define kAuxiliaryViewTag 251


@interface TPViewController () {
    AEChannelGroupRef  _loopsGroup;
}

@property (nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, retain) AEAudioFilePlayer *loop1;
@property (nonatomic, retain) AEAudioFilePlayer *loop2;
@property (nonatomic, retain) AEAudioFilePlayer *loop3;
@property (nonatomic, retain) AEAudioFilePlayer *sample1;
@property (nonatomic, retain) AEPlaythroughChannel *playthrough;
@property (nonatomic, retain) AELimiterFilter *limiter;
@property (nonatomic, retain) AEExpanderFilter *expander;
@property (nonatomic, retain) TPDoubleSpeedFilter *doubleSpeedFilter;
@property (nonatomic, retain) TPOscilloscopeLayer *outputOscilloscope;
@property (nonatomic, retain) TPOscilloscopeLayer *inputOscilloscope;
@property (nonatomic, retain) AERecorder *recorder;
@property (nonatomic, retain) AEAudioFilePlayer *player;
@property (nonatomic, retain) UILabel *channelCountLabel;
@property (nonatomic, retain) UIButton *recordButton;
@property (nonatomic, retain) UIButton *playButton;
@end

@implementation TPViewController
@synthesize audioController=_audioController,
            loop1=_loop1,
            loop2=_loop2,
            loop3=_loop3,
            sample1=_sample1,
            playthrough=_playthrough,
            limiter=_limiter,
            expander=_expander,
            doubleSpeedFilter=_doubleSpeedFilter,
            outputOscilloscope=_outputOscilloscope,
            inputOscilloscope=_inputOscilloscope,
            recorder=_recorder,
            player=_player,
            channelCountLabel = _channelCountLabel,
            recordButton = _recordButton,
            playButton = _playButton;

- (id)initWithAudioController:(AEAudioController*)audioController {
    if ( !(self = [super initWithStyle:UITableViewStyleGrouped]) ) return nil;
    
    self.audioController = audioController;
    
    self.loop1 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"caitlin" withExtension:@"caf"]
                                           audioController:_audioController
                                                     error:NULL];
    _loop1.volume = 1.0;
    _loop1.muted = YES;
    _loop1.loop = YES;
    
    self.loop2 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"congaloop" withExtension:@"caf"]
                                           audioController:_audioController
                                                     error:NULL];
    _loop2.volume = 1.0;
    _loop2.muted = YES;
    _loop2.loop = YES;
    
    self.loop3 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"dmxbeat" withExtension:@"aiff"]
                                           audioController:_audioController
                                                     error:NULL];
    _loop3.volume = 1.0;
    _loop3.muted = YES;
    _loop3.loop = YES;
    
    _loopsGroup = [_audioController createChannelGroup];
    [_audioController addChannels:[NSArray arrayWithObjects:_loop1, _loop2, _loop3, nil] toChannelGroup:_loopsGroup];
    
    return self;
}

-(void)dealloc {
    
    self.channelCountLabel = nil;
    
    NSMutableArray *channelsToRemove = [NSMutableArray arrayWithObjects:_loop1, _loop2, _loop3, _player, nil];

    self.loop1 = nil;
    self.loop2 = nil;
    self.loop3 = nil;
    self.player = nil;
    
    if ( _sample1 ) {
        [channelsToRemove addObject:_sample1];
        [_sample1 removeObserver:self forKeyPath:@"playing"];
        self.sample1 = nil;
    }
    
    if ( [channelsToRemove count] > 0 ) {
        [_audioController removeChannels:channelsToRemove];
    }
    
    [_audioController removeChannelGroup:_loopsGroup];

    if ( _playthrough ) {
        [_audioController removeInputReceiver:_playthrough];
        [_audioController removeChannels:[NSArray arrayWithObject:_playthrough]];
        self.playthrough = nil;
    }
    
    if ( _limiter ) {
        [_audioController removeFilter:_limiter];
        self.limiter = nil;
    }
    
    if ( _expander ) {
        [_audioController removeFilter:_expander];
        self.expander = nil;
    }
    
    if ( _doubleSpeedFilter ) {
        [_audioController setVariableSpeedFilter:nil];
        self.doubleSpeedFilter = nil;
    }
    
    self.recorder = nil;
    self.recordButton = nil;
    self.playButton = nil;
    
    self.outputOscilloscope = nil;
    self.inputOscilloscope = nil;
    
    self.audioController = nil;

    [super dealloc];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *oscilloscopeHostView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 100)] autorelease];
    oscilloscopeHostView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.outputOscilloscope = [[[TPOscilloscopeLayer alloc] init] autorelease];
    _outputOscilloscope.frame = oscilloscopeHostView.bounds;
    [oscilloscopeHostView.layer addSublayer:_outputOscilloscope];
    [_audioController addOutputReceiver:_outputOscilloscope];
    [_outputOscilloscope start];
    
    self.inputOscilloscope = [[[TPOscilloscopeLayer alloc] init] autorelease];
    _inputOscilloscope.frame = oscilloscopeHostView.bounds;
    _inputOscilloscope.lineColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    [oscilloscopeHostView.layer addSublayer:_inputOscilloscope];
    [_audioController addInputReceiver:_inputOscilloscope];
    [_inputOscilloscope start];
    
    self.tableView.tableHeaderView = oscilloscopeHostView;
    
    UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 80)] autorelease];
    self.recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [_recordButton setTitle:@"Stop" forState:UIControlStateSelected];
    [_recordButton addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    _recordButton.frame = CGRectMake(10, 10, ((footerView.bounds.size.width-30) / 2), footerView.bounds.size.height - 20);
    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_playButton setTitle:@"Play" forState:UIControlStateNormal];
    [_playButton setTitle:@"Stop" forState:UIControlStateSelected];
    [_playButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    _playButton.frame = CGRectMake(_recordButton.frame.origin.x+_recordButton.frame.size.width+10, 10, ((footerView.bounds.size.width-30) / 2), footerView.bounds.size.height - 20);
    [footerView addSubview:_recordButton];
    [footerView addSubview:_playButton];
    self.tableView.tableFooterView = footerView;
    
    self.channelCountLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _channelCountLabel.font = [UIFont boldSystemFontOfSize:12];
    _channelCountLabel.textColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    _channelCountLabel.backgroundColor = [UIColor clearColor];
    _channelCountLabel.shadowColor = [UIColor whiteColor];
    _channelCountLabel.shadowOffset = CGSizeMake(0, 1);
    [_channelCountLabel sizeToFit];
    _channelCountLabel.frame = CGRectOffset(_channelCountLabel.frame, 10, 10);
    [self.view addSubview:_channelCountLabel];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_audioController addObserver:self forKeyPath:@"numberOfInputChannels" options:0 context:NULL];
    _channelCountLabel.text = [NSString stringWithFormat:@"%d input channels", _audioController.numberOfInputChannels];
    [_channelCountLabel sizeToFit];
    _channelCountLabel.frame = CGRectOffset(_channelCountLabel.frame, 10, 10);
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_audioController removeObserver:self forKeyPath:@"numberOfInputChannels"];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return 3;
            break;
            
        case 1:
            return 1;
            
        case 2:
            return 3;
        
        case 3:
            return 1;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if ( !cell ) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[cell viewWithTag:kAuxiliaryViewTag] removeFromSuperview];
    
    switch ( indexPath.section ) {
        case 0: {
            cell.accessoryView = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
            UISlider *slider = [[[UISlider alloc] initWithFrame:CGRectMake(cell.bounds.size.width - cell.accessoryView.frame.size.width - 20 - 100, 0, 100, cell.bounds.size.height)] autorelease];
            slider.tag = kAuxiliaryViewTag;
            slider.maximumValue = 1.0;
            slider.minimumValue = 0.0;
            [cell addSubview:slider];
            
            switch ( indexPath.row ) {
                case 0: {
                    cell.textLabel.text = @"Loop 1";
                    ((UISwitch*)cell.accessoryView).on = !_loop1.muted;
                    slider.value = _loop1.volume;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(loop1SwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    [slider addTarget:self action:@selector(loop1VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Loop 2";
                    ((UISwitch*)cell.accessoryView).on = !_loop2.muted;
                    slider.value = _loop2.volume;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(loop2SwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    [slider addTarget:self action:@selector(loop2VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2: {
                    cell.textLabel.text = @"Loop 3";
                    ((UISwitch*)cell.accessoryView).on = !_loop3.muted;
                    slider.value = _loop3.volume;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(loop3SwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    [slider addTarget:self action:@selector(loop3VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
            }
            break;
        } 
        case 1: {
            cell.accessoryView = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [(UIButton*)cell.accessoryView setTitle:@"Play" forState:UIControlStateNormal];
            [(UIButton*)cell.accessoryView setTitle:@"Stop" forState:UIControlStateSelected];
            [(UIButton*)cell.accessoryView sizeToFit];
            
            switch ( indexPath.row ) {
                case 0: {
                    cell.textLabel.text = @"Sample 1";
                    [(UIButton*)cell.accessoryView setSelected:_sample1 != nil];
                    [(UIButton*)cell.accessoryView addTarget:self action:@selector(sample1PlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                }
            }
            break;
        }
        case 2: {
            cell.accessoryView = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
            
            switch ( indexPath.row ) {
                case 0: {
                    cell.textLabel.text = @"Limiter";
                    ((UISwitch*)cell.accessoryView).on = _limiter != nil;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(limiterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Expander";
                    ((UISwitch*)cell.accessoryView).on = _expander != nil;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(expanderSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2: {
                    cell.textLabel.text = @"Double Speed";
                    ((UISwitch*)cell.accessoryView).on = _doubleSpeedFilter != nil;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(useDoubleSpeedFilterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
            }
            break;
        }
        case 3: {
            cell.accessoryView = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
            
            switch ( indexPath.row ) {
                case 0: {
                    cell.textLabel.text = @"Input Playthrough";
                    ((UISwitch*)cell.accessoryView).on = _playthrough != nil;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(playthroughSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
            }
            break;
        }
            
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)loop1SwitchChanged:(UISwitch*)sender {
    _loop1.muted = !sender.isOn;
}

- (void)loop1VolumeChanged:(UISlider*)sender {
    _loop1.volume = sender.value;
}

- (void)loop2SwitchChanged:(UISwitch*)sender {
    _loop2.muted = !sender.isOn;
}

- (void)loop2VolumeChanged:(UISlider*)sender {
    _loop2.volume = sender.value;
}

- (void)loop3SwitchChanged:(UISwitch*)sender {
    _loop3.muted = !sender.isOn;
}

- (void)loop3VolumeChanged:(UISlider*)sender {
    _loop3.volume = sender.value;
}

- (void)sample1PlayButtonPressed:(UIButton*)sender {
    if ( _sample1 ) {
        [_audioController removeChannels:[NSArray arrayWithObject:_sample1]];
        [_sample1 removeObserver:self forKeyPath:@"playing"];
        self.sample1 = nil;
        [sender setSelected:NO];
    } else {
        self.sample1 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"lead" withExtension:@"aif"]
                                                 audioController:_audioController
                                                           error:NULL];
        [_sample1 addObserver:self forKeyPath:@"playing" options:0 context:sender];
        [_audioController addChannels:[NSArray arrayWithObject:_sample1]];
        [sender setSelected:YES];
    }
}

- (void)playthroughSwitchChanged:(UISwitch*)sender {
    if ( sender.isOn ) {
        self.playthrough = [[[AEPlaythroughChannel alloc] initWithAudioController:_audioController] autorelease];
        [_audioController addInputReceiver:_playthrough];
        [_audioController addChannels:[NSArray arrayWithObject:_playthrough]];
    } else {
        [_audioController removeChannels:[NSArray arrayWithObject:_playthrough]];
        [_audioController removeInputReceiver:_playthrough];
        self.playthrough = nil;
    }
}

- (void)limiterSwitchChanged:(UISwitch*)sender {
    if ( sender.isOn ) {
        self.limiter = [[[AELimiterFilter alloc] init] autorelease];
        _limiter.level = INT16_MAX * 0.1;
        [_audioController addFilter:_limiter];
    } else {
        [_audioController removeFilter:_limiter];
        self.limiter = nil;
    }
}

- (void)expanderSwitchChanged:(UISwitch*)sender {
    if ( sender.isOn ) {
        self.expander = [[[AEExpanderFilter alloc] init] autorelease];
        [_audioController addFilter:_expander];
    } else {
        [_audioController removeFilter:_expander];
        self.expander = nil;
    }
}

- (void)useDoubleSpeedFilterSwitchChanged:(UISwitch*)sender {
    if ( sender.isOn ) {
        self.doubleSpeedFilter = [[[TPDoubleSpeedFilter alloc] initWithAudioController:_audioController] autorelease];
        [_audioController setVariableSpeedFilter:_doubleSpeedFilter];
    } else {
        [_audioController setVariableSpeedFilter:nil];
        self.doubleSpeedFilter = nil;
    }
}

- (void)record:(id)sender {
    if ( _recorder ) {
        [_recorder finishRecording];
        [_audioController removeOutputReceiver:_recorder];
        [_audioController removeInputReceiver:_recorder];
        self.recorder = nil;
        _recordButton.selected = NO;
    } else {
        self.recorder = [[[AERecorder alloc] initWithAudioController:_audioController] autorelease];
        NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [[documentsFolders objectAtIndex:0] stringByAppendingPathComponent:@"Recording.m4a"];
        NSError *error = nil;
        if ( ![_recorder beginRecordingToFileAtPath:path fileType:kAudioFileM4AType error:&error] ) {
            [[[[UIAlertView alloc] initWithTitle:@"Error" 
                                         message:[NSString stringWithFormat:@"Couldn't start recording: %@", [error localizedDescription]]
                                        delegate:nil
                               cancelButtonTitle:nil
                               otherButtonTitles:@"OK", nil] autorelease] show];
            self.recorder = nil;
            return;
        }
        
        _recordButton.selected = YES;
        
        [_audioController addOutputReceiver:_recorder];
        [_audioController addInputReceiver:_recorder];
    }
}

- (void)play:(id)sender {
    if ( _player ) {
        [_audioController removeChannels:[NSArray arrayWithObject:_player]];
        self.player = nil;
        _playButton.selected = NO;
    } else {
        NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [[documentsFolders objectAtIndex:0] stringByAppendingPathComponent:@"Recording.m4a"];
        
        if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] ) return;
        
        NSError *error = nil;
        self.player = [AEAudioFilePlayer audioFilePlayerWithURL:[NSURL fileURLWithPath:path] audioController:_audioController error:&error];
        
        if ( !_player ) {
            [[[[UIAlertView alloc] initWithTitle:@"Error" 
                                         message:[NSString stringWithFormat:@"Couldn't start playback: %@", [error localizedDescription]]
                                        delegate:nil
                               cancelButtonTitle:nil
                               otherButtonTitles:@"OK", nil] autorelease] show];
            return;
        }
        
        _player.removeUponFinish = YES;
        [_audioController addChannels:[NSArray arrayWithObject:_player]];
        
        _playButton.selected = YES;
    }
}

-(void)setPlayer:(AEAudioFilePlayer *)player {
    if ( _player ) [_player removeObserver:self forKeyPath:@"playing"];
    [player retain];
    [_player release];
    _player = player;
    if ( _player ) [_player addObserver:self forKeyPath:@"playing" options:0 context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ( object == _sample1 ) {
        [_audioController removeChannels:[NSArray arrayWithObject:_sample1]];
        [_sample1 removeObserver:self forKeyPath:@"playing"];
        self.sample1 = nil;
        [(UIButton*)context setSelected:NO];
    } else if ( object == _player ) {
        self.player = nil;
        _playButton.selected = NO;
    } else if ( object == _audioController ) {
        _channelCountLabel.text = [NSString stringWithFormat:@"%d channels", _audioController.numberOfInputChannels];
        [_channelCountLabel sizeToFit];
    }
}

@end
