module.exports =
  pkg:
    name: "@makeform/bilingual", extend: {name: "@makeform/common"}
    dependencies: []
    i18n:
      "en":
        "en": "English"
        "zh": "Chinese"
      "zh-TW":
        "en": "英文"
        "zh": "中文"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t}) -> 
  {ldview} = ctx
  lc = {}
  init: ->
    @on \change, (v) ~>
      {zh,en} = @mod.child.nodes
      v = @content! or {}
      if zh.value == v.zh and en.value == v.en => return
      zh.value = v.zh or ''
      en.value = v.en or ''
      @mod.child.view.render <[preview ml-input content]>
    handler = ~>
      {zh,en} = @mod.child.nodes
      v = if @is-empty! => {} else @content!
      if zh.value == v.zh and en.value == v.en => return
      v <<< {zh: zh.value, en: en.value}
      @value {v}
    @mod.child.view = view = new ldview do
      init-render: false
      root: root
      action:
        focus:
          "ml-input": ({node}) ->
            node.classList.add \active
            (node.nextSibling or node.previousSibling).classList.remove \active
        input: "ml-input": handler
        change: "ml-input": handler
        click:
          "ml-input": ({node}) ->
            node.classList.add \active
            (node.nextSibling or node.previousSibling).classList.remove \active
      handler:
        "ml-input": ({node}) ~>
          lng = node.getAttribute \data-name
          use-lng = @mod.info.config.language or \both
          enabled = (lng == use-lng or !(use-lng in <[zh en]>))
          readonly = !enabled or !!@mod.info.meta.readonly
          if readonly => node.setAttribute \readonly, true
          else node.removeAttribute \readonly
          v = @content!
          node.classList.toggle \is-invalid, (enabled and @status! == 2)
          node.classList.toggle \d-none, !enabled
        content: ({node}) ~>
          val = @content!
          text = if @is-empty! => "n/a" else "#{val.zh or ''} / #{val.en or ''}"
          node.classList.toggle \text-muted, @is-empty!
          node.innerText = text
    @mod.child.nodes = Object.fromEntries(view.getAll(\ml-input).map -> [it.getAttribute(\data-name), it])
    @mod.child.view.render!

  render: ->
    @mod.child.view.render!

  is-empty: (v) ->
    v = @content(v)
    if (typeof(v) == \undefined) or (typeof(v) != \object) or v == null => return true
    use-lng = @mod.info.config.language
    zh = (v.zh or "").trim!
    en = (v.en or "").trim!
    if use-lng == \en and !en => return true
    else if use-lng == \zh and !zh => return true
    # use-lng == 'both'
    else if !(use-lng in <[en zh]>) and !(zh and en) => return true
    return false

  content: (v) -> if v and typeof(v) == \object => v.v else v

