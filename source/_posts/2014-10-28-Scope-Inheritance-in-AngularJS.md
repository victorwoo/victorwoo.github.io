---
layout: post
title: "AngularJS 中 $scope 的原型继承问题"
date: 2014-10-28 10:33:30
description: Scope Inheritance in AngularJS
categories: angularjs
tags: angularjs
---
# 问题描述

如下 AngularJS 代码的 INPUT 中键入“Separate reality”，执行效果是什么？

```javascript
var HelloCtrl = function ($scope) {
};
```

```html
<body ng-app ng-init="name='World'">
    <h1>Hello, {{name}}</h1>
    <div ng-controller="HelloCtrl">
        Say hello to: <input type="text" ng-model="name">
        <h2>Hello, {{name}}!</h2>
    </div>
</body>
```

# 执行结果

- 外层 H1 始终显示 World
- 内层 H2 先显示 World在 INPUT 中键入之后，H2 显示“Separate reality”。

# 原因

`ng-controller` 创建了一个新的 Scope，该作用域**原型继承于**父 Scope。

# 解决方案

## 方案 1 - 采用 `$parent` 访问父作用域

这种方法带导致强耦合，不提倡！

```javascript
<input type="text" ng-model="$parent.name">
```

## 方案 2 - 绑定到对象的属性

**最佳实践！**

```html
<body ng-app ng-init="thing = {name : 'World'}">
    <h1>Hello, {{thing.name}}</h1>
    <div ng-controller="HelloCtrl">
        Say hello to: <input type="text" ng-model=" thing.name">
        <h2>Hello, {{thing.name}}!</h2>
    </div>
</body>
```

# 模拟

以下例子模拟了原始问题 vs 解决方案 2。

```javascript
var a = {
    x: 1,
    y: {
        z: 2
    }
};

var b = {};
b.__proto__ = a;

console.log(b.x); // 1
console.log(b.y.z); // 2

// 原始问题
b.x = 11; // 模拟在 INPUT 中输入
console.log(a.x); // 1

// 解决方案 2
b.y.z = 22; // 模拟在 INPUT 中输入
console.log(a.y.z); // 22
```
