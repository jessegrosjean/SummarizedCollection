//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public func _addressString(for pointer: UnsafeRawPointer) -> String {
  let address = UInt(bitPattern: pointer)
  return "0x\(String(address, radix: 16))"
}

public func _addressString(for object: AnyObject) -> String {
  _addressString(for: Unmanaged.passUnretained(object).toOpaque())
}

@inlinable
public func _addressString<T: AnyObject>(for object: Unmanaged<T>) -> String {
  _addressString(for: object.toOpaque())
}

@inlinable
public func _arrayDescription<C: Collection>(
  for elements: C,
  debug: Bool = false,
  typeName: String? = nil
) -> String {
  var result = ""
  if let typeName = typeName {
    result += "\(typeName)("
  }
  result += "["
  var first = true
  for item in elements {
    if first {
      first = false
    } else {
      result += ", "
    }
    if debug {
      debugPrint(item, terminator: "", to: &result)
    } else {
      print(item, terminator: "", to: &result)
    }
  }
  result += "]"
  if typeName != nil { result += ")" }
  return result
}

@inlinable
public func _dictionaryDescription<Key, Value, C: Collection>(
  for elements: C,
  debug: Bool = false,
  typeName: String? = nil
) -> String where C.Element == (key: Key, value: Value) {
  var result = ""
  if let typeName = typeName {
    result += "\(typeName)("
  }

  if elements.isEmpty {
    result += "[:]"
  } else {
    result += "["
    var first = true
    for (key, value) in elements {
      if first {
        first = false
      } else {
        result += ", "
      }
      if debug {
        debugPrint(key, terminator: "", to: &result)
        result += ": "
        debugPrint(value, terminator: "", to: &result)
      } else {
        result += "\(key): \(value)"
      }
    }
    result += "]"
  }

  if typeName != nil {
    result += ")"
  }
  return result
}
