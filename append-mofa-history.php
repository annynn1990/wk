<?php
use MediaWikiCommentStoreCommentStoreComment;
use MediaWikiContentContentHandler;
use MediaWikiMaintenanceMaintenance;
use MediaWikiRevisionSlotRecord;
use MediaWikiTitleTitle;
use MediaWikiUserUser;

require_once '/var/www/html/maintenance/Maintenance.php';

class AppendMofaHistory extends Maintenance {
    public function __construct() {
        parent::__construct();
        $this->addDescription('Append Ministry of Foreign Affairs history to 外交部條例');
    }

    public function execute() {
        $title = Title::newFromText('外交部條例');
        if (!$title) {
            $this->fatalError('Invalid title');
        }

        $page = $this->getServiceContainer()->getWikiPageFactory()->newFromTitle($title);
        $oldContent = '';
        if ($page->exists()) {
            $content = $page->getContent();
            if ($content) {
                $oldContent = $content->serialize();
            }
        }

        if (strpos($oldContent, '== 歷史沿革 ==') !== false) {
            $this->output("歷史沿革已存在，略過。\n");
            return true;
        }

        $history = <<<'WIKI'

== 歷史沿革 ==

外交部成立於 2011 年 7 月 15 日。由於早期中文微國家生態尚未萌芽發展，外交事務極為稀少，該部門之成立較君主立憲制度實行之時間晚約六年。成立之初命名為「外務署」，首任外務大臣由關二哥出任；因早期外交需求極低，該部門曾被戲稱為「長蚊子的部門」。

2013 年 2 月 24 日，第五屆國會第二次會議中通過《外務部條例》，將「外務署」更名為「外務部」。2014 年 6 月 18 日，第九屆首相仲尼將「外務部」更名為「外交部」，首長職銜定為「外交大臣」。

此後，第二十屆內閣總理大臣紀文思在任期間，曾有因微國家聯盟需求而新設微盟事務大臣獨立存在，但時任微盟事務大臣與外交大臣都由關二哥兼任，於 2020 年 3 月 23 日合併職權，職銜短暫更名為「外交及微盟事務大臣」；直至 2021 年 2 月 17 日，由第二十三屆內閣總理大臣關二哥決議恢復原名「外交大臣」並持續沿用至今。

=== 名稱變遷一覽 ===

* '''外務署'''（2011 年－2013 年）
* '''外務部'''（2013 年－2014 年）
* '''外交部'''（2014 年－至今）
WIKI;

        $newText = rtrim($oldContent) . "\n" . $history . "\n";
        $newContent = ContentHandler::makeContent($newText, $title);

        $user = User::newSystemUser(User::MAINTENANCE_SCRIPT_USER, ['steal' => true]);
        $updater = $page->newPageUpdater($user);
        $updater->setContent(SlotRecord::MAIN, $newContent);
        $status = $updater->saveRevision(
            CommentStoreComment::newUnsavedComment('將外交部歷史沿革納入《外交部條例》')
        );

        if (!$status->isGood()) {
            $this->error($status);
            return false;
        }

        $this->output("外交部條例已加入歷史沿革。\n");
        return true;
    }
}

$maintClass = AppendMofaHistory::class;
require_once RUN_MAINTENANCE_IF_MAIN;
