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
@property LinearLayout* bg;
@property UILabel* filename_label;
@property UILabel* progress_label;
@property UIProgressView* progress_bar;
@property UILabel* content_label;
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

    self.bg = [[LinearLayout alloc] init];
    self.bg.direction = LAYOUT_VERTICAL;
    self.bg.frame = self.content_view.frame;
    [self.content_view addSubview:self.bg];

    self.filename_label = [[UILabel alloc]init];
    [self.filename_label setText:@"Filename.csv"];
    [self.filename_label setLLSize:50];
    [self.filename_label setAdjustsFontSizeToFitWidth:YES];
    [self.filename_label setTextAlignment:UITextAlignmentCenter];

    self.progress_label = [[UILabel alloc]init];
    [self.progress_label setText:@"0% Asshole"];
    [self.progress_label setLLSize:50];
    [self.progress_label setAdjustsFontSizeToFitWidth:YES];
    [self.progress_label setTextAlignment:UITextAlignmentCenter];

    self.progress_bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [self.progress_bar setProgress:0.5];
    [self.progress_bar setLLSize:20];

    self.content_label = [[UILabel alloc]init];
    self.content_label.numberOfLines = 0;
    [self.content_label setText:@"Yadda yadda yadda"];
    [self.content_label setLLWeight:1];
    [self.content_label setAdjustsFontSizeToFitWidth:NO];

    [self.bg addSubview:self.filename_label];
    [self.bg addSubview:self.progress_label];
    [self.bg addSubview:self.progress_bar];
    [self.bg addSubview:self.content_label];

    [self refreshProgress:nil];

    [self.log_file.meter downloadLog:self.log_file];
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
    [GCD asyncMain:^{
        [self.progress_bar setProgress:1];
        int dl_kb = [self.log_file getFileSize]/1024;
        [self.progress_label setText:[NSString stringWithFormat:@"Done!  Downloaded %dkB",dl_kb]];

        [self sendEmail];
    }];
}

-(void)sendEmail {
    MFMailComposeViewController * mc = [WidgetFactory makeEmailComposeWindow];
    [mc setSubject:@"Mooshimeter log"];
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
