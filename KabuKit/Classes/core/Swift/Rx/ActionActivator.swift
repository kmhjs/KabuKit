//
//  Copyright © 2017 crexista
//

import Foundation
import RxSwift

/**
 SceneのActionを監視するクラスです.
 
 */
public class ActionActivator<DestinationType: Destination> {
    
    var actionTypeHashMap: [String : SignalClosable]? = [String : SignalClosable]()
    
    var disposableMap: [String : [ActionEvent]]? = [String : [ActionEvent]]()
    
    let director: Director<DestinationType>
    
    /**
     指定のActionを有効化させます.
     
     - attention: activateできるActionのインスタンスには条件があります
     
       * activateできるActionは1クラスにつき1インスタンスまでです.
     
       * すでにactivateされているactionを再度activateしても何も起きません
     
       * ただし、deactivate済みのactionであれば再度activateをします
     
     - parameters:
       - action: activateされるActionプロトコルを実装したクラスインスタンス
       - onStart: actionが開始される直前に呼ばれるコールバック
     
     - returns: activateが実行され、actionが有効化されたらtrueを返します.
                すでにactivate済みのインスタンスがactionに指定された場合は何もされないため
                falseを返します
     */
    @discardableResult
    public func activate<A: Action>(action: A, onStart: () -> Void = {}) -> Bool where A.DestinationType == DestinationType {
        let typeName = String(describing: type(of: action))
        
        guard disposableMap?[typeName] == nil else {
            return false
        }

        actionTypeHashMap?[typeName] = actionTypeHashMap?[typeName] ?? action

        disposableMap?[typeName] = action.invoke(director: director).map{ (target) in
            target.start(action: action, recoverHandler: recover)
            return target
        }
        
        onStart()
        return true
    }
    
    /**
     指定のActionをサスペンド状態にします.
     
     これで指定されたActionのSignalは全て破棄され、
     再度activateされるまでイベントを飛ばすことはありません
     
     */
    public func deactivate<A: Action>(actionType: A.Type) -> Bool where A.DestinationType == DestinationType {
        // 指定のクラス名に紐づくDisposableを取得し
        // 全て破棄し、DisposableMapも空にする
        let typeName = String(describing: actionType)
        return deactivateByTypeName(typeName: typeName)

    }
    
    /**
     このactivatorで管理されている全ての Actionをサスペンド状態にします
     
     */
    public func deactivateAll() {
        actionTypeHashMap?.keys.forEach { (typeName) in
            _ = self.deactivateByTypeName(typeName: typeName)
        }
    }
    
    /**
     指定のActionが現在動いているか(activateされている状態か)どうかを返します
     
     - parameters:
       - actionType: Actionの型
     - returns: 指定のActionが現在動いている場合は `true` そうでない場合は `false` を返します
     */
    public func isActive(actionType: SignalClosable.Type) -> Bool {
        let typeName = String(describing: actionType)
        return disposableMap?[typeName] != nil
    }
    
    /**
     Actionの型情報をキーとしてactivate済みのActionのインスタンスを取得します
     
     - parameters: 
       - actionType: Actionの型
     */
    public func resolve<A: Action>(actionType: A.Type) -> A? where A.SceneType.RouterType.DestinationType == DestinationType {
        let typeName = String(describing: actionType)

        return actionTypeHashMap?[typeName] as? A
    }
    
    /**
     クラス名指定によってActionをサスペンド状態にします.

     - parameters:
       - typeName: クラス名
     
     - returns: サスペンドに成功したらtrue, サスペンドが行われなかったらfalseを返します
     */
    private func deactivateByTypeName(typeName: String) -> Bool {
        guard let disposables = disposableMap?[typeName] else {
            return false
        }

        disposables.forEach { (disposable) in
            disposable.dispose()
        }

        actionTypeHashMap?[typeName]?.onStop()
        _ = disposableMap?.removeValue(forKey: typeName)

        return true
    }
    
    /**
     キャッチ損ねエラー発生時のリカバー処理を行います
     
     */
    internal func recover<A: Action>(error: ActionError<A>, pattern: RecoverPattern) {
        switch pattern {
        case .reloadErrorSignal(let onStart):
            let action = error.from
            error.event.dispose()
            error.event.start(action: action, recoverHandler: recover)
            onStart()
        case .doNothing:
            break
        }
    }
    
    deinit {
        deactivateAll()
        actionTypeHashMap?.removeAll()
        disposableMap = nil
        actionTypeHashMap = nil
    }
    
    internal init(director: Director<DestinationType>) {
        self.director = director
    }
}
