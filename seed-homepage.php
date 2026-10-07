<?php
require_once '/var/www/html/maintenance/Maintenance.php';

class SeedWongmingHomepage extends Maintenance {
    public function __construct() {
        parent::__construct();
        $this->addDescription('Initialize the Wongming Empire encyclopedia homepage');
    }

    public function execute() {
        $title = Title::newFromText('Main Page');
        $page = WikiPage::factory($title);
        $text = file_get_contents('/tmp/homepage.wiki');
        $content = ContentHandler::makeContent($text, $title);
        $user = User::newSystemUser('Maintenance script', ['stealable' => false]);
        $page->doUserEditContent($content, $user, '建立黃名帝國百科首頁', EDIT_NEW | EDIT_FORCE_BOT);
    }
}

$maintClass = SeedWongmingHomepage::class;
require_once RUN_MAINTENANCE_IF_MAIN;
