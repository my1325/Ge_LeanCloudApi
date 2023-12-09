//
//  Ge_LCApi.swift
//  Ge_LCApi
//
//  Created by my on 2023/12/9.
//

import Foundation

public enum Ge_LCApiAction {
    public enum Ge_LCClasses {
        /// 创建对象（POST）
        case ge_create(ge_className: String)
        /// 获取对象（GET）
        case ge_get(ge_className: String, ge_objectId: String)
        /// 更新对象 （PUT）
        case ge_update(ge_className: String, ge_objectId: String)
        /// 查询对象（GET）
        case ge_query(ge_className: String)
        /// 删除对象（DELETE）
        case ge_delete(ge_className: String, ge_objectId: String)
        
        var ge_pathComponents: [String] {
            switch self {
            case let .ge_create(ge_className), let .ge_query(ge_className):
                return [ge_className]
            case let .ge_get(ge_className, ge_objectId),
                let .ge_update(ge_className, ge_objectId),
                let .ge_delete(ge_className, ge_objectId):
                return [ge_className, ge_objectId]
            }
        }
    }
    ///
    case ge_classes(Ge_LCClasses)
    
    /// 按照特定顺序遍历 Class（GET）
    case ge_scanClasses(ge_className: String)

    
    public enum Ge_LCRoles {
        /// 创建角色（POST）
        case ge_create
        /// 获取角色（GET）
        case ge_get(ge_objectId: String)
        /// 更新角色（PUT）
        case ge_update(ge_objectId: String)
        /// 查询角色（GET）
        case ge_query
        /// 删除角色（DELETE）
        case ge_delete(ge_objectId: String)
        
        var ge_pathComponents: [String] {
            switch self {
            case .ge_create, .ge_query:
                return []
            case let .ge_get(ge_objectId),
                let .ge_update(ge_objectId),
                let .ge_delete(ge_objectId):
                return [ge_objectId]
            }
        }
    }
    case ge_roles(Ge_LCRoles)
    
    public enum Ge_LCSchemas {
        /// 获取应用所有 Class 的 Schema（GET）
        case ge_getAll
        /// 获取应用指定 Class 的 Schema（GET）
        case ge_getClass(ge_className: String)
        
        var ge_pathComponents: [String] {
            switch self {
            case .ge_getAll: return []
            case let .ge_getClass(ge_className): return [ge_className]
            }
        }
    }
    case ge_schemas(Ge_LCSchemas)
    
    /// 获得服务端当前时间（GET）
    case ge_getDate
    public enum Ge_LCExportData {
        /// 请求导出应用数据（POST）
        case ge_exportData
        /// 获取导出数据任务状态和结果（GET）
        case ge_exportDataWithId(ge_id: String)
        
        var ge_pathComponents: [String] {
            switch self {
            case .ge_exportData: return []
            case let .ge_exportDataWithId(ge_id): return [ge_id]
            }
        }
    }
    case ge_exportData(Ge_LCExportData)
    
    var ge_pathComponents: [String] {
        switch self {
        case let .ge_classes(ge_classes): return ["classes"] + ge_classes.ge_pathComponents
        case let .ge_scanClasses(ge_className): return ["scan", "classes", ge_className]
        case let .ge_roles(ge_roles): return ["roles"] + ge_roles.ge_pathComponents
        case let .ge_schemas(ge_schemas): return ["schemas"] + ge_schemas.ge_pathComponents
        case .ge_getDate: return ["date"]
        case let .ge_exportData(ge_exportData): return ["exportData"] + ge_exportData.ge_pathComponents
        }
    }
}

public struct Ge_LCApi {
    let ge_version: String
    let ge_host: String
    let ge_appId: String
    let ge_appKey: String
    let ge_action: Ge_LCApiAction
}

public extension Ge_LCApi {
    var ge_requestUrl: URL {
        guard var ge_url = URL(string: ge_host) else {
            fatalError("\(ge_host) is not valid url string")
        }
        let ge_pathComponents = [ge_version] + ge_action.ge_pathComponents
        return ge_url.appendingPathComponent(ge_pathComponents.joined(separator: "/"))
    }
    
    var ge_headers: [String: String] {
        [
            "X-LC-Id": ge_appId,
            "X-LC-Key": ge_appKey
        ]
    }
}
