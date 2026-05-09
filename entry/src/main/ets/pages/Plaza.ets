import { router } from '@kit.ArkUI';
import { PrivateLetter } from '../models/Types';
import { apiService } from '../services/ApiService';

@Component
export struct Plaza {
  @State posts: PrivateLetter[] = [];
  @State isLoading: boolean = false;
  @State showCreateDialog: boolean = false;
  @State newContent: string = '';

  aboutToAppear() {
    this.loadPosts();
  }

  async loadPosts() {
    this.isLoading = true;
    try {
      await apiService.ensureAnonymousUser();
      let res = await apiService.listPosts(50);
      this.posts = res.posts || [];
    } catch (e) {
      console.error('Failed to load posts', e);
    } finally {
      this.isLoading = false;
    }
  }

  async publishPost() {
    if (!this.newContent.trim()) return;
    try {
      let res = await apiService.createPost(this.newContent.trim());
      this.posts.unshift(res.post);
      this.showCreateDialog = false;
      this.newContent = '';
    } catch (e) {
      console.error('Publish error:', e);
      // In real app, show toast error here
    }
  }

  async react(postId: string, type: string) {
    try {
      await apiService.addReaction(postId, type);
      // Optional: show a small toast or animation
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

      // Posts List
      if (this.isLoading && this.posts.length === 0) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else {
        List({ space: 16 }) {
          ForEach(this.posts, (post: PrivateLetter) => {
            ListItem() {
              this.PostCard(post)
            }
          }, (item: PrivateLetter) => item.id)
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
            
            TextArea({ placeholder: '分享你的情绪或倾诉...', text: this.newContent })
              .height(120)
              .onChange((v) => this.newContent = v)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .margin({ bottom: 24 })
              
            Row() {
              Button('取消')
                .backgroundColor('transparent')
                .fontColor($r('app.color.color_unselected'))
                .onClick(() => { this.showCreateDialog = false; })
              Blank()
              Button('发布')
                .backgroundColor($r('app.color.color_primary'))
                .fontColor($r('app.color.color_white'))
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

  @Builder PostCard(post: PrivateLetter) {
    Column() {
      Row() {
        Circle().width(32).height(32).fill('#E2D9FF')
        Column() {
          // Since it's anonymous, use a placeholder or generic name
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
        this.ReactionBtn('抱抱', () => this.react(post.id, 'hug'))
        this.ReactionBtn('我懂你', () => this.react(post.id, 'understand'))
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