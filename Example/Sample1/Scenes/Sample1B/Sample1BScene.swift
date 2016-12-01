//
//  Sample1BScene.swift
//  Example
//
//  Created by crexista on 2016/11/24.
//  Copyright © crexista. All rights reserved.
//

import Foundation
import KabuKit

extension Sample1BViewController : ActionScene {
    
    typealias TransitionType = Sample1BLink
    typealias ArgumentType = Void
    
    enum Sample1BLink : SceneTransition {
        typealias StageType = UIViewController        
        case A
        case B
        
        func request(context: SceneContext<UIViewController>) -> SceneChangeRequest? {
            switch self {
            case .A:
                let xib = ViewControllerXIBFile("Sample1AViewController", Bundle.main)
                return context.sceneRequest(xib, Sample1AViewController.self, true) { (stage, scene) in
                    stage.navigationController?.pushViewController(scene, animated: true)
                }
            case .B:
                let xib = ViewControllerXIBFile("Sample1BViewController", Bundle.main)
                return context.sceneRequest(xib, Sample1BViewController.self, nil) { (stage, scene) in
                    stage.navigationController?.pushViewController(scene, animated: true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
        let action = Sample1BAction(label: label, buttonA: nextButtonA, buttonB: nextButtonB, prevButton: prevButton)
        actor.activate(action: action, director: self.director, argument: self.argument)
    }
    
    func onRelease(stage: UIViewController) -> Bool {
        _ = stage.navigationController?.popViewController(animated: true)
        return true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if (self.navigationController == nil && !isReleased) {
            _ = director.exit()
        }
    }
    
}
