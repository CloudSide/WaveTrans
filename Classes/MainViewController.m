//
//  MainViewController.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "MainViewController.h"
#import "MainTableViewCell.h"
#import "TableViewCellFactory.h"
#import "MSCMoreOptionTableViewCell.h"
#import "WaveTransMetadata.h"

#import "WaveTransModel.h"


@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate,MSCMoreOptionTableViewCellDelegate,UIActionSheetDelegate>

@property (nonatomic,retain) UITableView *mTableView;

@property (nonatomic,retain) NSMutableArray *metadataList;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.metadataList = [WaveTransModel metadataList];
    
    if (self.metadataList.count ==0) {
        
        for (int i = 0; i<10; i++) {
            WaveTransMetadata *wt = [[WaveTransMetadata alloc] initWithSha1:[NSString stringWithFormat:@"356a192b7913b04c54574d18c28d46e6395428a%d",i]
                                                                       type:@"file"
                                                                    content:@"http://sdfsdf"
                                                                       size:1212
                                                                   filename:@"av.mp3"];
            [wt save];
            [wt release];
        }
        self.metadataList = [WaveTransModel metadataList];
    }
    
    self.mTableView = [[UITableView alloc] initWithFrame:self.view.frame];
    self.mTableView.delegate = self;
    self.mTableView.dataSource = self;
    [self.mTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    [self.view addSubview:self.mTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource<NSObject>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.metadataList.count;
}

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 4;
//}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Called when "DELETE" button is pushed.
    NSLog(@"DELETE button pushed in row at: %@", indexPath.description);
    //TODO:删除按钮
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WaveTransMetadata *wt =[self.metadataList objectAtIndex:indexPath.row];
    
    MainTableViewCell *cell = [TableViewCellFactory getTableViewCellByCellType:wt
                                                                     tableView:tableView owner:self];
    
    return cell;
}

//-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    switch (section) {
//        case 0:
//        return @"今天";
//        case 1:
//        return @"昨天";
//        case 2:
//        return @"前天";
//        case 3:
//        return @"星期四";
//    }
//    
//    return @"一周前";
//}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)] autorelease];
//    header.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
//    
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 100, 20)];
//    [header addSubview:titleLabel];
//    
//    switch (section) {
//        case 0:
//        titleLabel.text = @"今天";
//        break;
//        
//        case 1:
//        titleLabel.text = @"昨天";
//        break;
//        
//        case 2:
//        titleLabel.text = @"前天";
//        break;
//        
//        case 3:
//        titleLabel.text = @"星期四";
//        break;
//        
//        //TODO:......
//        
//        default:
//        titleLabel.text = @"一周以前";
//        break;
//    }
//    
//    return header;
//}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

#pragma mark - MSCMoreOptionTableViewCellDelegate
- (void)tableView:(UITableView *)tableView moreOptionButtonPressedInRowAtIndexPath:(NSIndexPath *)indexPath {
    // Called when "MORE" button is pushed.
    NSLog(@"MORE button pushed in row at: %@", indexPath.description);
    [self showMoreActionSheet:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForMoreOptionButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"More";
}

-(UIColor *)tableView:(UITableView *)tableView backgroundColorForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UIColor colorWithRed:0.18f green:0.67f blue:0.84f alpha:1.0f];
}

#pragma mark - actionSheet
-(void)showMoreActionSheet:(NSIndexPath *)indexPath
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"取消"
                                               destructiveButtonTitle:@"删除"
                                                    otherButtonTitles:@"用其他软件打开",@"分享",@"详细",nil];
    
    [actionSheet showInView:self.view];
    [actionSheet release];
}

#pragma mark - UIActionSheetDelegate <NSObject>

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //TODO:action sheet 更多按钮
}

@end
