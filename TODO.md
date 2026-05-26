# TODO

現時点の JS / CSS 改善案メモ。

運用ルール:
- 実施済みの項目は `TODO.md` に残さず、完了した時点で削除する。

## JavaScript

### High

- [ ] `source/javascripts/search.js`
  `#search` 要素と `window.PagefindUI` の存在チェックを入れる。検索 UI が読み込まれないページでも安全にしたい。

- [ ] `source/javascripts/diary.js`
  `pre.address` の「2 行目が住所」という前提をやめられる形を検討する。将来的には住所行に class を付けるか、HTML 側で構造を明示した方が安全。

- [ ] `source/javascripts/editor.js`
  保存失敗時のエラーハンドリングを少し固くする。`response.json()` 前提をやめて、JSON 以外のレスポンスでもメッセージを出せるようにしたい。

### Medium

- [ ] `source/javascripts/photoswipe-init.js`
  グローバル関数 `initPhotoSwipeFromDOM` と `editor.js` の結合を弱める。再初期化用関数を分けるか、責務を分離したい。

### Low

- [ ] `source/javascripts/search.js`
  未使用の引数や細かな書式を整理する。

- [ ] `source/javascripts/diary.js`
  `decorateImageParagraphs()` の条件判定が今後増えそうなら、小さな helper 関数に分ける。

## CSS

### High

- [ ] `source/stylesheets/style.css`
  `#search` の `float` ベースのレイアウトをやめて、周辺と同じく flex / grid に寄せる。

### Medium

- [ ] `source/stylesheets/style.css`
  `rgba(...)` や `box-shadow` の生値をもう少し token 化する。特にカード系、`pre.*`、Pagefind 周辺はまだ直値が多い。

- [ ] `source/stylesheets/style.css`
  `.mainblock` の独立スクロールを維持するか見直す。長文ページでの操作感とアンカー移動の挙動を確認したい。

- [ ] `source/stylesheets/style.css`
  `backdrop-filter` や全面固定背景の装飾を `@supports` で分岐するか検討する。環境によっては描画コストが高い。

### Low

- [ ] `source/stylesheets/edit.css`
  editor 用スタイルの色や余白も、必要なら `style.css` 側の design token に寄せて揃える。
