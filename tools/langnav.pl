#!/usr/bin/perl
# 全ページの言語切り替え（ヘッダーの言語メニュー・フッターの言語リンク・hreflang）を
# 下の言語一覧から書き込む。言語を追加したら一覧に1行足して実行し直す。
#
#   使い方（サイトのフォルダで）: perl tools/langnav.pl
#
# 各ページには次の目印を置いておく（中身はこのスクリプトが毎回作り直す）:
#   <!-- langnav:hreflang:start --><!-- langnav:hreflang:end -->   … <head> 内
#   <!-- langnav:menu:start --><!-- langnav:menu:end -->           … ヘッダー内
#   <!-- langnav:footer:start --><!-- langnav:footer:end -->       … フッター内
use utf8;
use strict;
use warnings;
binmode STDOUT, ':utf8';

# [言語コード(hreflang), ヘルプのファイル, プライバシーポリシーのファイル, 表示名]
my @langs = (
    ['ja',      'index.html', 'privacy.html',    '日本語'],
    ['en',      'en.html',    'privacy-en.html', 'English'],
    ['ko',      'ko.html',    'privacy-ko.html', '한국어'],
    ['zh-Hans', 'zh.html',    'privacy-zh.html', '中文（简体）'],
    ['es',      'es.html',    'privacy-es.html', 'Español'],
    ['fr',      'fr.html',    'privacy-fr.html', 'Français'],
    ['de',      'de.html',    'privacy-de.html', 'Deutsch'],
    ['pt',      'pt.html',    'privacy-pt.html', 'Português'],
    ['it',      'it.html',    'privacy-it.html', 'Italiano'],
);
my $default = 'en';  # x-default（言語が合わないときに案内するページ）

my $globe = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>';

sub replace_block {
    my ($html, $name, $content, $file) = @_;
    my $n = ($$html =~ s{(<!-- langnav:$name:start -->).*?(<!-- langnav:$name:end -->)}{$1$content$2}s);
    die "$file: marker langnav:$name not found\n" unless $n;
}

for my $kind (1, 2) {  # 1 = ヘルプ, 2 = プライバシーポリシー
    for my $cur (@langs) {
        my $file = $cur->[$kind];
        open(my $in, '<:encoding(UTF-8)', $file) or die "$file: $!\n";
        local $/; my $html = <$in>; close $in;

        my $hreflang = join('', map { "\n<link rel=\"alternate\" hreflang=\"$_->[0]\" href=\"$_->[$kind]\">" } @langs)
            . "\n<link rel=\"alternate\" hreflang=\"x-default\" href=\""
            . (grep { $_->[0] eq $default } @langs)[0]->[$kind] . "\">\n";

        my $items = join('', map {
            my $current = $_->[0] eq $cur->[0] ? ' aria-current="page"' : '';
            "\n        <li><a href=\"$_->[$kind]\" lang=\"$_->[0]\" hreflang=\"$_->[0]\"$current>$_->[3]</a></li>"
        } @langs);
        my $menu = "\n    <details class=\"lang-menu\">\n      <summary>$globe $cur->[3]</summary>\n      <ul>$items\n      </ul>\n    </details>\n    ";

        my $footer = "\n  <div class=\"footer-langs\">"
            . join('', map { "<a href=\"$_->[$kind]\" lang=\"$_->[0]\" hreflang=\"$_->[0]\">$_->[3]</a>" } @langs)
            . "</div>\n  ";

        replace_block(\$html, 'hreflang', $hreflang, $file);
        replace_block(\$html, 'menu', $menu, $file);
        replace_block(\$html, 'footer', $footer, $file);

        open(my $out, '>:encoding(UTF-8)', $file) or die "$file: $!\n";
        print $out $html; close $out;
        print "updated $file\n";
    }
}
