path = require 'path'
Q = require 'q'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'

module.exports =
class GoToView extends SymbolsView
  toggle: ->
    if @panel.isVisible()
      @cancel()
    else
      @populate()

  detached: ->
    @deferredFind?.resolve([])

  findTag: (editor) ->
    @deferredFind?.resolve([])

    deferred = Q.defer()
    TagReader.find editor, (error, matches=[]) -> deferred.resolve(matches)
    @deferredFind = deferred
    @deferredFind.promise

  populate: ->
    editor = atom.workspace.getActiveTextEditor()

    # Logic added for the experiment
    fromFile = editor.buffer.file.path
    fromLine = editor.getCursorBufferPosition().row + 1
    if editor.getLastCursor().getScopeDescriptor().getScopesArray().indexOf('source.ruby') isnt -1
      # Include ! and ? in word regular expression for ruby files
      range = editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /[\w!?]*/g)
    else
      range = editor.getLastCursor().getCurrentWordBufferRange()
    targetMethod = editor.getTextInRange(range)


    return unless editor?

    @findTag(editor).then (matches) =>
      tags = []
      for match in matches
        position = @getTagLine(match)
        continue unless position
        match.name = path.basename(match.file)
        match.order = _i                   # Logic added for the experiment
        match.fromFile = fromFile          # Logic added for the experiment
        match.fromLine = fromLine          # Logic added for the experiment
        match.targetMethod = targetMethod  # Logic added for the experiment
        tags.push(match)

      if tags.length is 1

        tags[0].order = -1        # Logic added for the experiment

        @openTag(tags[0])
      else if tags.length > 0
        @setItems(tags)
        @attach()
