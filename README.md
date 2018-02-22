## svn 提交插件
`@yangqing`
> date@2017-12-29

* 使用说明：
 1. 复制svn.vim到~/.vim/plugin/
 ```
 cp svn.vim ~/.vim/plugin/
 ```
 2. 在vimrc中增加如下配置:
 ```
 command! Qsvn :call Q_SvnStatus()
 ```
 3. 运行vim直接调用`Qsvn`函数即可,
 ```
 :Qsvn
 ```
 4. 按键 `<F1>` 显示帮助信息
