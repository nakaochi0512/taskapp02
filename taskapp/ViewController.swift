//
//  ViewController.swift
//  taskapp
//
//  Created by 米住直親 on 2017/06/08.
//  Copyright © 2017年 naochika.yonezumi. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!
    
    
    var task:Task!
    //realm のインスタンス呼び出し
    let  realm  = try!Realm()
    
    
    //データーベス内のタスクを格納するリスト
    //日付が近い順でソート
    //以降内容が更新されるごとにソート
    //降順trueであれば昇順
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    //検索結果リザルト
    var searchResult = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //入力なしにリターンキーを押せるようにする
        SearchBar.enablesReturnKeyAutomatically = false
        
        
        tableview.delegate = self
        tableview.dataSource = self
        SearchBar.delegate = self
        //検索ボタン押した時のメソッド
    
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //キーボードを閉じる。
        SearchBar.endEditing(true)
    }
    //検索バーが変更されたときのメソッド
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        
        //検索がからの時にすべて表示
        if searchText.isEmpty{
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
        }else{
            taskArray = try! Realm().objects(Task.self).filter("Category == %@" ,searchText).sorted(byKeyPath: "date", ascending: false)
            //searcgBr空のときの処理
            //タイトルと一致しているれば表示
            
        }
        //検索した際にテーブルビューを再リロード
        tableview.reloadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    //配列の数を返すメソッド
    //taskArrayの要素数をcountにてセルの数を調べる。
    //テーブルviewのセルの行数を表示
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return taskArray.count
    }
    
    
    //セルないの行数を表示
    // 各セルの内容を返すメソッド
    //TaskAllayより該当するデータを取り出してセルに設定する。
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        //indexpathは現在タッチしているセル。
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        
        // Cellに値を設定する.
        //task＝行数
        //formatter=日付
        //datestring=メモ？？
        
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        searchResult = [task.title]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date as Date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    //識別子cellsegue
    //送信者はありません。
    //セルをタップした時に実行されるメソッド
    //ViewControllerのセルをタップした時に呼ばれるtableView:didSelectRowAtIndexPath:メソッドに、segueのIDを指定して遷移させる
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellsegue", sender:nil)
    }
    // 各セルを選択した時に実行されるメソッド
    
    // セルが削除が可能なことを伝えるメソッド
    //tableView:editingStyleForRowAtIndexPath:メソッドはセルが削除が可能かどうか、並び替えが可能かどうかなどどのように編集ができるかを返すメソッド
    //indexpathは選択しているセルの行
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
        
    }
    
    //画面推移の際に呼び出されるメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellsegue" {
            let indexPath = self.tableview.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            task.date = NSDate()
            
            if taskArray.count != 0 {
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableview.reloadData()
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    //tableView:commitEditingStyle:forRowAtIndexPath:メソッドはセルが削除されるときに呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    
}

