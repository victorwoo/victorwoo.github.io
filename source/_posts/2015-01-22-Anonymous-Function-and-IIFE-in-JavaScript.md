layout: post
title: "JavaScript 中的匿名函数和立即执行函数"
date: 2015-01-22 11:27:15
description: "Anonymous Function and IIFE in JavaScript"
categories:
- javascript
tags:
- javascript
---
命名函数
--------
```javascript
function foo() {

}
```

这种写法和 C 语言中定义一个函数的写法差不多。

匿名函数 + 赋值语句
-------------------
```javascript
var bar = function() {

};
```

例子中变量 `bar` 指向一个匿名函数。由于这是一个赋值语句，所以应该以 `;` 结尾。虽然分号可以省略。

命名函数 + 赋值语句
-------------------
```javascript
var bar = function foo() {

};
```

此处的 `foo` 可以省略，不会影响代码逻辑。但是加上 `foo` 在调试工具中查看调用堆栈时，可以更清晰地看到函数的名称。所以这是一个推荐的实践。

立即执行函数 (IIFE)
-------------------
```javascript
(function() {

}());
```

还有一种变体：

```javascript
(function() {

})();
```

请注意上述两种写法的圆括号的位置区别。前一种写法是 JSLint 推荐的写法，所以推荐采用第一种写法。

这种模式本质上只是一个函数表达式（无论是命名或匿名的），该函数会在创建后立刻执行。以下是用命名函数来实现 IIFE 的例子：

```javascript
(function foo() {
    var bar = 1;
}());
```

代码中用 `foo` 作为 IIFE 的名字。

这种模式是非常有用的，因为它为初始化代码提供了一个作用于沙箱(sandbox)。代码中的 `bar` 变量此时会成为一个局部变量，不会污染全局的 `window` (`global`) 对象。
