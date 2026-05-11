import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { PublicPost } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct Plaza {
  @State posts: PublicPost[] = [];
  @State isLoading: boolean = false;
  @State showCreateDialog: boolean = false;
  @State newTitle: string = '';
  @State newContent: string = '';
  @State allowComments: boolean = true;
  @State searchText: string = '';
  @State statusText: string = '匿名广场';

  aboutToAppear() {
    this.loadPosts();
  }

  async loadPosts() {
    this.isLoading = true;
    try {
      await apiService.ensureAnonymousUser();
      let res = await apiService.listPosts(50);
      this.posts = res.posts || [];
      this.statusText = this.posts.length > 0 ? `已加载 ${this.posts.length} 条匿名内容` : '还没有匿名帖子';
    } catch (e) {
      this.statusText = '加载失败，请检查后端是否启动';
      console.error('Failed to load posts', e);
    } finally {
      this.isLoading = false;
    }
  }

  get filteredPosts(): PublicPost[] {
    const keyword = this.searchText.trim().toLowerCase();
    if (!keyword) {
      return this.posts;
    }
    return this.posts.filter((post: PublicPost) => {
      return (post.content || '').toLowerCase().includes(keyword) || (post.title || '').toLowerCase().includes(keyword);
    });
  }

  async publishPost() {
    if (!this.newContent.trim()) return;
    try {
      let res = await apiService.createPost(this.newContent.trim(), this.newTitle || undefined, this.allowComments);
      this.posts.unshift(res.post);
      this.showCreateDialog = false;
      this.newTitle = '';
      this.newContent = '';
      this.allowComments = true;
      this.statusText = '匿名帖子已发布';
      promptAction.showToast({ message: '匿名帖子已发布' });
    } catch (e) {
      console.error('Publish error:', e);
      promptAction.showToast({ message: '发布失败' });
    }
  }

  async react(postId: string, type: string) {
    try {
      await apiService.addReaction(postId, type);
      promptAction.showToast({ message: '已回应' });
    } catch (e) {
      console.error('React error:', e);
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('匿名广场')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))
        Blank()
        Button('发帖')
          .fontSize(14)
          .backgroundColor($r('app.color.color_primary'))
          .fontColor($r('app.color.color_white'))
          .height(32)
          .borderRadius(16)
          .onClick(() => { this.showCreateDialog = true; })
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.color_white'))

      Row() {
        TextInput({ placeholder: '搜索匿名内容', text: this.searchText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((v: string) => { this.searchText = v; })
        Button('刷新').margin({ left: 10 }).onClick(() => this.loadPosts())
      }
      .padding({ left: 16, right: 16, bottom: 8 })

      // Posts List
      if (this.isLoading && this.posts.length === 0) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.posts.length === 0) {
        Column() {
          Text('还没有匿名帖子')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 40 })
          Text('先发第一条匿名表达吧')
            .fontSize(13)
            .fontColor('#888888')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List({ space: 16 }) {
          ForEach(this.filteredPosts, (post: PublicPost) => {
            ListItem() {
              this.PostCard(post)
            }
          }, (item: PublicPost) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
      
      // Dialog
      if (this.showCreateDialog) {
        // Overlay mask
        Stack({ alignContent: Alignment.Center }) {
          Rect()
            .width('100%')
            .height('100%')
            .fill('rgba(0,0,0,0.4)')
            .onClick(() => { this.showCreateDialog = false; })
            
          Column() {
            Text('发布匿名帖子')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })
            Text('请确认内容中没有真实姓名、手机号、宿舍号、微信号等隐私信息。')
              .fontSize(12)
              .fontColor('#8B849B')
              .margin({ bottom: 12 })
            
            TextInput({ placeholder: '标题（可选）', text: this.newTitle })
              .height(42)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .margin({ bottom: 10 })
              .onChange((v: string) => this.newTitle = v)

            TextArea({ placeholder: '分享你的情绪或倾诉...', text: this.newContent })
              .height(120)
              .onChange((v: string) => this.newContent = v)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .margin({ bottom: 14 })
              
            Row() {
              Text('允许评论')
                .fontSize(13)
                .fontColor('#666666')
              Toggle({ type: ToggleType.Switch, isOn: this.allowComments })
                .onChange((isOn: boolean) => this.allowComments = isOn)
              Blank()
              Button('取消')
                .backgroundColor('transparent')
                .fontColor($r('app.color.color_unselected'))
                .onClick(() => { this.showCreateDialog = false; })
              Button('发布')
                .backgroundColor($r('app.color.color_primary'))
                .fontColor($r('app.color.color_white'))
                .margin({ left: 10 })
                .onClick(() => this.publishPost())
            }
            .width('100%')
          }
          .width('85%')
          .backgroundColor($r('app.color.color_white'))
          .borderRadius(16)
          .padding(24)
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(999)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4FF')
  }

  @Builder PostCard(post: PublicPost) {
    Column() {
      Row() {
        Circle().width(32).height(32).fill('#E2D9FF')
        Column() {
          Text('匿名同学')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.color_text_primary'))
          Text(new Date(post.created_at).toLocaleString())
            .fontSize(10)
            .fontColor($r('app.color.color_unselected'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      
      Text(post.content)
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .lineHeight(22)
        .margin({ top: 12, bottom: 16 })
        .width('100%')
        
      Row() {
        this.ReactionBtn('抱抱', (): void => { this.react(post.id, 'hug'); })
        this.ReactionBtn('我懂你', (): void => { this.react(post.id, 'understand'); })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_white'))
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }

  @Builder ReactionBtn(label: string, action: () => void) {
    Button(label)
      .fontSize(12)
      .height(28)
      .backgroundColor('#F0E9FF')
      .fontColor($r('app.color.color_primary'))
      .borderRadius(14)
      .margin({ right: 12 })
      .onClick(action)
  }
}