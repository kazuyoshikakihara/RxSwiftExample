//
//  ViewController.swift
//  RssReaderWithoutRx
//
//  Created by Kazuyoshi Kakihara on 2017/12/04.
//  Copyright © 2017年 Kazuyoshi Kakihara. All rights reserved.
//

import UIKit
import FeedKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate {

    /// 読み込み対象のフィードの配列
    private let rssFeeds = [
        ("TechChrunch Japan", "http://jp.techcrunch.com/feed/"),
        ("Engadget Japaneese", "http://japanese.engadget.com/rss.xml"),
        ("Impress Watch", "http://www.watch.impress.co.jp/headline/rss/headline.rdf"),
        ("ASCII.jp", "http://ascii.jp/cate/1/rss.xml"),
        ("GIZMODO", "https://www.gizmodo.jp/index.xml"),
        ("GIGAZINE", "http://gigazine.net/news/rss_2.0/"),
        ("マイナビニュース", "http://feeds.news.mynavi.jp/rss/mynavi/index"),
        ("ITmedia", "http://rss.itmedia.co.jp/rss/2.0/itmedia_all.xml")
    ]

    /// フィードアイテムの内容を保持するstruct
    private struct RssFeedItem {
        let title: String?
        let date: Date?
        let link: String?
    }

    /// フィード読み込みの結果を保持する配列
    private var rssFeedItems: [RssFeedItem] = []

    /// storyboard上のpickerView
    @IBOutlet weak var rssPickerView: UIPickerView!

    /// storyboard上のtableView
    @IBOutlet weak var entriesTableView: UITableView!

    /// Loadボタンがタップされたときの動作
    ///
    /// - Parameter sender: Action発生元
    @IBAction func onLoadButtonTapped(_ sender: Any) {
        // feedを読み、テーブルビューに反映させる
        loadRssFeed()
    }
    
    /// バックグラウンドでFeedを読み、Parseし、テーブルビューに反映する
    func loadRssFeed() {
        let urlString = rssFeeds[rssPickerView.selectedRow(inComponent: 0)].1
        let feedURL = URL(string: urlString)!
        let parser = FeedParser(URL: feedURL)
        parser?.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            switch result {
            case let .atom(feed):
                self.rssFeedItems = feed.entries?.map({
                    RssFeedItem(
                        title: $0.title,
                        date: $0.updated,
                        link: $0.links?.first?.attributes?.href)}) ?? []
            case let .rss(feed):
                self.rssFeedItems = feed.items?.map({
                    RssFeedItem(
                        title: $0.title,
                        date: $0.pubDate,
                        link: $0.link)}) ?? []
            case let .json(feed):
                self.rssFeedItems = feed.items?.map({
                    RssFeedItem(
                        title: $0.title,
                        date: $0.datePublished,
                        link: $0.url)}) ?? []
            case let .failure(error):
                print(error)
                return
            }

            // UI更新はメインキューで
            DispatchQueue.main.async {
                self.entriesTableView.reloadData()
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

    // MARK: UIViewController のライフサイクルイベント

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: UIPickerViewDataSource

    /// UIPickerViewの列の数を返す
    ///
    /// - Parameter in: UIPickerView
    /// - Returns: 列の数
    func numberOfComponents(in: UIPickerView) -> Int {
        return 1
    }

    /// UIPickerViewの行の数を返す
    ///
    /// - Parameters:
    ///   - pickerView: UIPickerView
    ///   - component: 列番号
    /// - Returns: 行の数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return rssFeeds.count
    }

    // MARK: UIPickerViewDelegate

    /// UIPickerViewの行ごとに表示する文字列
    ///
    /// - Parameters:
    ///   - pickerView: UIPickeerView
    ///   - row: 行の位置
    ///   - component: 列の位置
    /// - Returns: 表示する文字列
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return rssFeeds[row].0
    }

    // MARK: UITableViewDataSource

    /// UITableViewのセルの内容をセット
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: 対象のcellのindexPath
    /// - Returns: 生成されたcell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "RssTableViewCell")
        let rssFeedItem = rssFeedItems[indexPath.row]

        // エントリーのタイトルをセット
        cell.textLabel?.text = rssFeedItem.title ?? ""

        // エントリーの日付をja_JP localeでセット
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        if let date = rssFeedItem.date {
            cell.detailTextLabel?.text = dateFormatter.string(from: date)
        } else {
            cell.detailTextLabel?.text = "-"
        }

        return cell
    }

    /// UITableViewの行数
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - section: セクション番号
    /// - Returns: 行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rssFeedItems.count
    }

    // MARK: UITableViewDelegate

    /// UITableViewのセルが選択されたときの動作。標準ブラウザを起動する
    ///
    /// - Parameters:
    ///   - tableView: 選択されたtableView
    ///   - indexPath: 選択されたindexPath
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let link = rssFeedItems[indexPath.row].link {
            openApplicationWithUrlString(urlString: link)
        }
    }
}
