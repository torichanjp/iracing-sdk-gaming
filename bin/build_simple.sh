#!/bin/bash

set -eu

# タグやブランチ名に「/」が入っていると失敗になるため、「-」に置換する。
VERSION=$(echo $1 | sed -r 's#/#-#g')
# 画像パス変換で必要なので取っておく。
ORG_VERSION=$1
echo "VERSION: $VERSION"
echo "ORG_VERSION: $ORG_VERSION"

BIN_DIR="$(dirname $0)"

BASE_DIR="$(cd ${BIN_DIR}/..; pwd)"
echo "BASE_DIR: $BASE_DIR"

BUILD_DIR="$BASE_DIR/build"
SRC_DIR="$BASE_DIR/plugins"

# buildディレクトリ削除
echo "Deleting a build directory $BUILD_DIR..."

if [[ -d "${BUILD_DIR}" ]]
then
    rm -rf "${BUILD_DIR}"
fi

echo "Done"
echo


#
# plugins以下をbuildにコピー
#
echo "Copyng files in $SRC_DIR to $BUILD_DIR..."
cp -a ${SRC_DIR} ${BUILD_DIR}
echo "Done"

ls -R $BUILD_DIR
echo

cd "${BUILD_DIR}"

# MarkDownからPDFを作成
echo "Generating PDF file(s) from MarkDown..."

export LANG=ja_JP.utf-8

# ./**/*.mdがなぜかgithub環境だと動かないので1ファイルずつ出力する
# pdfにしたとき、パブリックURLでないと表示できないので置換する。
# (../images/.....)→(https://github.com/torichanjp/iracing-sdk-gaming/blob/${VERSION}/images/.....?raw=true)
for i in $(find . -name '*.md'); do
  echo "Target file: ${i}..."
  sed -ri \
   's#]\((\.\./)+images/(.*)\)$#](https://github.com/torichanjp/iracing-sdk-gaming/blob/'${ORG_VERSION}'/images/\2?raw=true)#g' \
   $i
  npx md-to-pdf $i
  if [[ $? != 0 ]]; then
      echo "Failed to make PDF file(s)" 2>&1
      exit 1
  fi
  echo "Finished"
done

echo "Done"
echo

# 元のmdファイルを削除
echo "Delete markdown file(s)..."
find ${BUILD_DIR} -name '*.md' -exec rm {} \;

echo "Done"
echo
echo "Packaging..."
zip -r ${BUILD_DIR}/sdk-gaming-plugins-by-torichanjp-${VERSION}.zip .
if [[ $? != 0 ]];then
    "Fail" 2>&1
    exit 1
fi
echo "Success"

exit 0
