/**************************
Mooshimeter iOS App - interface to Mooshimeter wireless multimeter
Copyright (C) 2015  James Whong

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************/

#import "DownloadVC.h"
#import "GCD.h"
#import "LinearLayout.h"
#import "UIView+Toast.h"
#import "WidgetFactory.h"

@interface DownloadVC()
@property LogFile* log_file;
@property UILabel* filename_label;
@property UILabel* progress_label;
@property UIProgressView* progress_bar;
@property UILabel* content_label;
@property UIImageView* share_button;
@property BOOL done;
@end

@implementation DownloadVC

////////////////////
// Lifecycle methods
////////////////////

-(instancetype)initWithLogfile:(LogFile *)log{
    self = [super init];
    self.log_file = log;
    [self.log_file.meter addDelegate:self];
    _done = NO;
    return self;
}

-(void)viewWillDisappear:(BOOL)animated {
    [self.log_file.meter cancelLogDownload];
    [self.log_file.meter removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"Downloading file"];

    self.filename_label = [[UILabel alloc]init];
    [self.filename_label setText:@"Filename.csv"];
    [self.filename_label setLLSize:50];
    [self.filename_label setAdjustsFontSizeToFitWidth:YES];
    [self.filename_label setTextAlignment:UITextAlignmentCenter];
    [self.filename_label setText:[self.log_file getFileName]];

    self.progress_label = [[UILabel alloc]init];
    [self.progress_label setText:@"0%"];
    [self.progress_label setLLSize:50];
    [self.progress_label setAdjustsFontSizeToFitWidth:YES];
    [self.progress_label setTextAlignment:UITextAlignmentCenter];

    self.progress_bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [self.progress_bar setProgress:0.5];
    [self.progress_bar setLLSize:20];

    self.content_label = [[UILabel alloc]init];
    self.content_label.numberOfLines = 0;
    [self.content_label setText:@"Log Contents Displayed Here"];
    [self.content_label setLLWeight:1];
    [self.content_label setAdjustsFontSizeToFitWidth:NO];
    [self.content_label setTextAlignment:UITextAlignmentCenter];

    self.share_button = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"share.png"]];
    [self.share_button setLLSize:100];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shareButtonTapped:)];
    tap.numberOfTapsRequired = 1;
    [self.share_button setUserInteractionEnabled:YES];
    [self.share_button addGestureRecognizer:tap];

    // Now that we've instantiated all the widgets, lay them out

    LinearLayout* bg = [[LinearLayout alloc] initWithDirection:LAYOUT_VERTICAL];
    bg.frame = CGRectInset(self.content_view.frame,20,20);
    [self.content_view addSubview:bg];

    LinearLayout* top_pane = [[LinearLayout alloc] initWithDirection:LAYOUT_HORIZONTAL];
    [top_pane setLLSize:100];

    LinearLayout* progress_pane = [[LinearLayout alloc] initWithDirection:LAYOUT_VERTICAL];
    [progress_pane setLLWeight:1];
    [progress_pane addSubview:self.filename_label];
    [progress_pane addSubview:self.progress_label];

    [top_pane addSubview:progress_pane];
    [top_pane addSubview:self.share_button];

    [bg addSubview:top_pane];
    [bg addSubview:self.progress_bar];
    [bg addSubview:self.content_label];

    [self refreshProgress:nil];

    [self.log_file.meter downloadLog:self.log_file];
}

-(void)shareButtonTapped:(UITapGestureRecognizer*)rec {
    if(!self.done) {
        [self.content_view makeToast:@"Can't share until log download complete!"];
    } else {
        [self sendEmail];
    }
}

-(void)refreshProgress:(NSData*)data {
    [GCD asyncMain:^{
        if(data!=nil) {
            [self.content_label setText:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
        }
        uint32_t dl_bytes = [self.log_file getFileSize];
        int dl_kb = dl_bytes/1024;
        int total_kb = self.log_file.bytes/1024;
        float progress = (float)dl_bytes/(float)self.log_file.bytes;
        [self.progress_bar setProgress:progress];
        [self.progress_label setText:[NSString stringWithFormat:@"Downloaded %d of %dkB",dl_kb,total_kb]];
    }];
}

-(void)onLogDataReceived:(LogFile *)log data:(NSData *)data {
    [self refreshProgress:data];
}

-(void)onLogFileReceived:(LogFile *)log {
    self.done = YES;
    [GCD asyncMain:^{
        [self.progress_bar setProgress:1];
        int dl_kb = [self.log_file getFileSize]/1024;
        [self.progress_label setText:[NSString stringWithFormat:@"Done!  Downloaded %dkB",dl_kb]];

        [self sendEmail];
    }];
}

-(void)sendEmail {
    MFMailComposeViewController * mc = [WidgetFactory makeEmailComposeWindow];
    NSString* subject = @"Mooshimeter log ";
    subject = [subject stringByAppendingString:[self.log_file getFileName]];
    [mc setSubject:subject];
    [mc setMessageBody:@"This is a log from a Mooshimeter" isHTML:NO];

    // Get the resource path and read the file using NSData
    NSString *fileName = [self.log_file getFileName];
    NSData *fileData = [NSData dataWithContentsOfFile:[self.log_file getFilePath]];

    // Add attachment
    [mc addAttachmentData:fileData mimeType:@"text/plain" fileName:fileName];

    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}

@end
