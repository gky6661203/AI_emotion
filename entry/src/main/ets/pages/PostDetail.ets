import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';
import { PublicPost } from '../models/Types';

interface CommentItem {
  id: string;
  post_id: string;
  user_id: string;
  content: string;
  created_at: string;
}

@Entry
@Component
struct PostDetail {
  @State postId: string = '';
  @State post: PublicPost | null = null;
  @State comments: CommentItem[] = [];
  @State newComment: string = '';
  @State isLoading: boolean = true;
  @State postStatus: string = '加载中';
  @State currentUserId: string = '';
  @State commentHint: string = '写一点温和回应吧';

  aboutToAppear() {
    interface PostParams {
      postId?: string;
    }
    try {
      const params = router.getParams() as PostParams;
      this.postId = params?.postId || '';
    } catch (err) {
      console.error('getParams failed', err);
      this.postId = '';
    }
    this.load();
  }

  async load() {
    if (!this.postId) {
      this.isLoading = false;
      return;
    }
    try {
      const me = await apiService.ensureAnonymousUser();
      this.currentUserId = me.id || '';
      const postRes = await apiService.listPosts(100);
      this.post = (postRes.posts || []).find((item) => item.id === this.postId) || null;
      if (this.post) {
        this.postStatus = this.post.allow_comments ? '允许评论' : '评论已关闭';
      }
      const commentRes = await apiService.listComments(this.postId);
      this.comments = commentRes.comments || [];
      this.commentHint = this.comments.length > 0 ? '可以看看大家的回应，再写一句温和留言' : '这里还没有评论，先做第一个温和回应吧';
    } catch (error) {
      console.error('Load post detail failed:', error);
      this.postStatus = '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async sendComment() {
    if (!this.newComment.trim()) {
      try {
        promptAction.showToast({ message: '请先写一点内容' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      return;
    }
    try {
      await apiService.createComment(this.postId, this.newComment.trim());
      this.newComment = '';
      await this.load();
      try {
        promptAction.showToast({ message: '评论已发布' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    } catch (error) {
      console.error('Create comment failed:', error);
      try {
        promptAction.showToast({ message: '评论发布失败' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    }
  }

  async deleteComment(commentId: string) {
    try {
      await apiService.deleteComment(this.postId, commentId);
      await this.load();
      try {
        promptAction.showToast({ message: '评论已删除' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    } catch (error) {
      console.error('Delete comment failed:', error);
      try {
        promptAction.showToast({ message: '删除失败' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    }
  }

  build() {
    Column() {
      Row() {
        Text('帖子详情').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Text(this.postStatus).fontSize(11).fontColor('#8B849B').margin({ right: 12 })
        Button('返回').onClick(() => {
          try {
            router.back();
          } catch (err) {
            console.error('back failed', err);
          }
        })
      }.width('100%').padding(16)

      if (this.isLoading) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.post) {
        Scroll() {
          Column() {
            Column() {
              Text(this.post.title || '匿名帖子').fontSize(18).fontWeight(FontWeight.Bold)
              Text(this.post.content).fontSize(15).lineHeight(22).margin({ top: 12 })
              Row() {
                Text(this.post.allow_comments ? '可评论' : '已关闭评论').fontSize(11).fontColor('#7B57FF')
                if (this.post.topic) {
                  Text(` · ${this.post.topic}`).fontSize(11).fontColor('#8B849B')
                }
                Blank()
                Text(new Date(this.post.created_at).toLocaleString()).fontSize(11).fontColor('#8B849B')
              }.margin({ top: 10 }).width('100%')
            }.padding(16).backgroundColor('#FFFFFF').borderRadius(16).margin({ left: 16, right: 16 })

            Column() {
              Row() {
                Text('评论').fontSize(16).fontWeight(FontWeight.Bold)
                Blank()
                Text(`${this.comments.length} 条`).fontSize(11).fontColor('#999999')
              }.width('100%').margin({ bottom: 8 })
              Text(this.commentHint).fontSize(11).fontColor('#8B849B').margin({ bottom: 8 })
              TextArea({ placeholder: '写下温和回应…', text: this.newComment })
                .height(100)
                .backgroundColor('#F5F5F5')
                .borderRadius(12)
                .onChange((v: string) => this.newComment = v)
              Row() {
                Button('发布评论').margin({ top: 10 }).onClick(() => this.sendComment())
                Blank()
                Button('刷新评论').margin({ top: 10 }).onClick(() => this.load())
              }
              Text('评论请保持温和，不要泄露个人隐私。').fontSize(11).fontColor('#8B849B').margin({ top: 8 })
            }.padding(16).backgroundColor('#FFFFFF').borderRadius(16).margin({ left: 16, right: 16, top: 12 })

            List({ space: 12 }) {
              ForEach(this.comments, (item: CommentItem) => {
                ListItem() {
                  Column() {
                    Text(item.content).fontSize(14).lineHeight(20)
                    Row() {
                      Text(new Date(item.created_at).toLocaleString()).fontSize(10).fontColor('#888888')
                      Blank()
                      if (item.user_id === this.currentUserId) {
                        Button('删除自己的评论').fontSize(10).height(26).onClick(() => this.deleteComment(item.id))
                      }
                    }.width('100%').margin({ top: 6 })
                  }.padding(14).backgroundColor('#FFFFFF').borderRadius(14)
                }
              }, (item: CommentItem) => item.id)
            }.padding({ left: 16, right: 16, top: 12, bottom: 16 })
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F4F1FF')
      }
    }.width('100%').height('100%').backgroundColor('#F7F4FF')
  }
}
