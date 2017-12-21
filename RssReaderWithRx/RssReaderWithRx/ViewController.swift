//
//  ViewController.swift
//  RssReaderWithRx
//
//  Created by Kazuyoshi Kakihara on 2017/12/04.
//  Copyright © 2017年 Kazuyoshi Kakihara. All rights reserved.
//

import UIKit
import FeedKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    /// rx用のDisposeBag
    private let disposeBag = DisposeBag()

    /// 読み込み対象のフィードの配列
    private let rssFeeds = [
        ("TechChrunch Japan", "http://jp.techcrunch.com/feed/"),
        ("Engadget Japaneese", "http://japanese.engadget.com/rss.xml"),
        ("Impress Watch", "http://www.watch.impress.co.jp/headline/rss/headline.rdf"),
        ("ASCII.jp", "http://ascii.jp/cate/1/rss.xml"),
        ("GIZMODO", "https://www.gizmodo.jp/index.xml"),
        ("GIGAZINE", "http://gigazine.net/news/rss_2.0/"),
        ("マイナビニュース", "http://feeds.news.mynavi.jp/rss/mynavi/index"),
        ("ITmedia", "http://rss.itmedia.co.jp/rss/2.0/itmedia_all.xml")]

    /// フィードアイテムの内容を保持するstruct
    private struct RssFeedItem {
        let title: String?
        let date: Date?
        let link: String?
    }

    /// フィード読み込みの結果を保持する配列、Variableとして宣言
    private var rssFeedItems: Variable<[RssFeedItem]> = Variable([])

    /// storyboard上のpickerView
    @IBOutlet weak var rssPickerView: UIPickerView!

    /// storyboard上のtableView
    @IBOutlet weak var entriesTableView: UITableView!

    /// storyboard上のloadButton
    @IBOutlet weak var loadButton: UIButton!

    /// バックグラウンドでFeedを読み、Parseし、rssFeedItemsにセットする（テーブルには自動反映される）
    func loadRssFeed() {
        let urlString = rssFeeds[rssPickerView.selectedRow(inComponent: 0)].1
        let feedURL = URL(string: urlString)!
        let parser = FeedParser(URL: feedURL)
        parser?.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            switch result {
            case let .atom(feed):
                self.rssFeedItems.value = feed.entries?.map({
                    RssFeedItem(
                        title: $0.title,
                        date: $0.updated,
                        link: $0.links?.first?.attributes?.href)}) ?? []
            case let .rss(feed):
                self.rssFeedItems.value = feed.items?.map({
                    RssFeedItem(
                        title: $0.title,
                        date: $0.pubDate,
                        link: $0.link)}) ?? []
            case let .json(feed):
                self.rssFeedItems.value = feed.items?.map({
                    RssFeedItem(
                        title: $0.title,
                        date: $0.datePublished,
                        link: $0.url)}) ?? []
            case let .failure(error):
                print(error)
                return
            }
        }
    }

    /// 与えられたURL文字列に対応したアプリケーションを起動する
    ///
    /// - Parameter urlString: アプリケーションを起動させるURL文字列
    func openApplicationWithUrlString(urlString: String) {
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    // MARK: UIViewControllerのライフサイクルイベント

    override func viewDidLoad() {
        super.viewDidLoad()

        // pickerView初期化
        Observable.just(rssFeeds)
            .bind(to: rssPickerView.rx.itemTitles) { _, item in
                return item.0
            }
            .disposed(by: disposeBag)

        // loadButton タップ時の動作
        loadButton.rx.tap
            .subscribe({ [unowned self] _ in
                self.loadRssFeed()
            })
            .disposed(by: disposeBag)

        // tableView初期化（セルの表示設定）
        rssFeedItems.asObservable()
            .bind(to: entriesTableView.rx.items) { (tableview, row, rssFeedItem) in
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "RssTableViewCell")

                // エントリーのタイトルをセット
                cell.textLabel?.text = rssFeedItem.title ?? ""

                // エントリーの日付をja_JP localeでセット
                if let date = rssFeedItem.date {
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "ja_JP")
                    dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                    cell.detailTextLabel?.text = dateFormatter.string(from: date)
                } else {
                    cell.detailTextLabel?.text = "-"
                }

                return cell
            }
            .disposed(by: disposeBag)

        // tableViewのセルをタップしたときの動作
        entriesTableView.rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                if let link = self.rssFeedItems.value[indexPath.row].link {
                    self.openApplicationWithUrlString(urlString: link)
                }
            })
            .disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
