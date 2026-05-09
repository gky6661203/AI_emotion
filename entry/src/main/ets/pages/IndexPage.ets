import { router } from '@kit.ArkUI';
import { Plaza } from './Plaza';

@Entry
@Component
struct IndexPage {
  @State scrollY: number = 0;
  @State tabIndex: number = 0;
  @State tabScales: number[] = [1, 1, 1, 1, 1];
  @State focusProgress: number[] = [0];

  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    setTimeout(() => {
      this.focusProgress = [68];
    }, 100);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll(this.scroller) {
        Column() {
          this.TopStack()
          this.StatusGrid()
          this.RecommendCards()
        // bottom padding for tabs
        Row().height(100).width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .onScroll(() => {
      this.scrollY = this.scroller.currentOffset().yOffset;
    })
    .backgroundColor($r('app.color.color_white'))

    // Floating Voice Record Button
    Stack({ alignContent: Alignment.BottomEnd }) {
      Button() {
        Text('🎤').fontSize(24)
      }
      .type(ButtonType.Circle)
      .width(56)
      .height(56)
      .backgroundColor($r('app.color.color_primary'))
      .shadow({ radius: 8, color: $r('app.color.color_shadow'), offsetY: 4 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/VoiceRecord' });
      })
      .margin({ right: 24, bottom: 100 }) // Avoid tabs
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)

    this.BottomTabs()
  }
  .width('100%')
  .height('100%')
  }

  @Builder TopStack() {
    Stack({ alignContent: Alignment.Bottom }) {
      Image($rawfile('bg.webp'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Crop)

      // Linear gradient mask
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [[$r('app.color.color_white'), 0.0], [$r('app.color.color_transparent_60'), 0.4]]
        })
        .blendMode(BlendMode.OVERLAY)
        .opacity(Math.max(0, 1 - this.scrollY / 500)) // sync gradient opacity with scroll

      // 3D Model
      Image($rawfile('model.glb'))
        .width(180)
        .height(240)
        .rotate({ x: 0, y: 1, z: 0, angle: (this.scrollY % 360) })
        .margin({ bottom: 0 })

      Text($r('app.string.top_greeting'))
        .fontFamily('HarmonyOS Sans')
        .fontSize($r('app.float.top_text_size'))
        .fontWeight(500)
        .fontColor($r('app.color.color_text_primary'))
        .position({ x: 32, y: 64 })
    }
    .width('100%')
    .height(300)
  }

  @Builder StatusGrid() {
    Grid() {
      GridItem() {
        Column() {
          Image($r('app.media.layered_image'))
            .width($r('app.float.icon_size'))
            .height($r('app.float.icon_size'))
            .fillColor($r('app.color.color_primary'))
          Text($r('app.string.grid_emotion'))
            .fontSize($r('app.float.grid_text_size'))
            .fontColor($r('app.color.color_text_primary'))
            .margin({ top: 8 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      }
      .height($r('app.float.grid_item_height'))
      .borderRadius($r('app.float.grid_radius'))
      .backgroundColor($r('app.color.color_transparent_40'))
      .backgroundBlurStyle(BlurStyle.Thin)

      GridItem() {
        Column() {
          Image($r('app.media.layered_image'))
            .width($r('app.float.icon_size'))
            .height($r('app.float.icon_size'))
            .fillColor($r('app.color.color_primary'))
          Text($r('app.string.grid_scene'))
            .fontSize($r('app.float.grid_text_size'))
            .fontColor($r('app.color.color_text_primary'))
            .margin({ top: 8 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      }
      .height($r('app.float.grid_item_height'))
      .borderRadius($r('app.float.grid_radius'))
      .backgroundColor($r('app.color.color_transparent_40'))
      .backgroundBlurStyle(BlurStyle.Thin)

      GridItem() {
        Column() {
          Stack() {
            DataPanel({ values: this.focusProgress, max: 100, type: DataPanelType.Circle })
              .width($r('app.float.icon_size'))
              .height($r('app.float.icon_size'))
              .valueColors([[{ color1: $r('app.color.color_primary'), color2: $r('app.color.color_secondary') }, 1.0]])
              .strokeWidth(8)
              .animation({ duration: 300, curve: Curve.Spring })
          }
          Text($r('app.string.grid_focus'))
            .fontSize($r('app.float.grid_text_size'))
            .fontColor($r('app.color.color_text_primary'))
            .margin({ top: 8 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      }
      .height($r('app.float.grid_item_height'))
      .borderRadius($r('app.float.grid_radius'))
      .backgroundColor($r('app.color.color_transparent_40'))
      .backgroundBlurStyle(BlurStyle.Thin)
    }
    .columnsTemplate("1fr 1fr 1fr")
    .rowsTemplate("auto")
    .columnsGap(12)
    .padding(16)
    .width('100%')
  }

  @Builder RecommendCards() {
    List({ space: 20 }) {
      ListItem() {
        this.CardItem($r('app.string.rec_title_1'), $r('app.string.rec_sub_1'))
      }
      ListItem() {
        this.CardItem($r('app.string.rec_title_2'), $r('app.string.rec_sub_2'))
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
  }

  @Builder CardItem(title: Resource, sub: Resource) {
    Row() {
      Image($r('app.media.layered_image'))
        .width(112)
        .height(112)
        .borderRadius($r('app.float.img_radius'))
        .margin({ left: 24 })

      Column() {
        Text(title)
          .fontSize($r('app.float.title_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))
        Text(sub)
          .fontSize($r('app.float.sub_size'))
          .fontColor($r('app.color.color_unselected'))
          .margin({ top: 8 })
        
        AnimatedButton({ text: $r('app.string.btn_meet') })
          .margin({ top: 16 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16, right: 24 })
      .layoutWeight(1)
    }
    .width('100%')
    .height($r('app.float.card_height'))
    .borderRadius($r('app.float.card_radius'))
    .linearGradient({
      angle: 90,
      colors: [[$r('app.color.color_grad_start'), 0.0], [$r('app.color.color_grad_end'), 1.0]]
    })
    .shadow({
      radius: 16,
      color: $r('app.color.color_shadow'),
      offsetY: 4
    })
  }

  @Builder BottomTabs() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent().tabBar(this.TabBuilder(0, $r('app.string.tab_home'), $r('app.media.ic_home')))
      TabContent().tabBar(this.TabBuilder(1, $r('app.string.tab_treehole'), $r('app.media.ic_treehole')))
      TabContent().tabBar(this.TabBuilder(2, $r('app.string.tab_pour'), $r('app.media.ic_pour')))
      TabContent() {
        if (this.tabIndex === 3) {
          Plaza()
        }
      }.tabBar(this.TabBuilder(3, $r('app.string.tab_discover'), $r('app.media.ic_discover')))
      TabContent().tabBar(this.TabBuilder(4, $r('app.string.tab_mine'), $r('app.media.ic_mine')))
    }
    .onChange((index: number) => {
      this.tabIndex = index;
      this.animateTab(index);
    })
    .backgroundColor($r('app.color.color_transparent_80'))
    .backdropBlur($r('app.float.blur_radius'))
    .width('100%')
    .height(80)
  }

  @Builder TabBuilder(index: number, name: Resource, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.tabIndex === index ? $r('app.color.color_icon_active') : $r('app.color.color_icon_normal'))
      Text(name)
        .fontColor(this.tabIndex === index ? $r('app.color.color_icon_active') : $r('app.color.color_icon_normal'))
        .fontSize(12)
        .margin({ top: 4 })
    }
    .scale({ x: this.tabScales[index], y: this.tabScales[index] })
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  private animateTab(index: number) {
    animateTo({ duration: 150, curve: Curve.EaseInOut }, () => {
      this.tabScales[index] = 1.2;
    });
    setTimeout(() => {
      animateTo({ duration: 150, curve: Curve.EaseInOut }, () => {
        this.tabScales[index] = 1.0;
      });
    }, 150);
  }
}

@Component
struct AnimatedButton {
  @Prop text: Resource;
  @State isPressed: boolean = false;

  build() {
    Button(this.text)
      .height($r('app.float.btn_height'))
      .borderRadius($r('app.float.btn_radius'))
      .fontSize(14)
      .fontColor($r('app.color.color_white'))
      .linearGradient({
        angle: 90,
        colors: this.isPressed ? 
          [[$r('app.color.color_primary_dark'), 0.0], [$r('app.color.color_primary_dark'), 1.0]] : 
          [[$r('app.color.color_primary'), 0.0], [$r('app.color.color_primary_dark'), 1.0]]
      })
      .scale({ x: this.isPressed ? 0.95 : 1, y: this.isPressed ? 0.95 : 1 })
      .opacity(this.isPressed ? 0.8 : 1)
      .animation({ duration: 150, curve: Curve.EaseInOut })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.isPressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false;
        }
      })
  }
}
