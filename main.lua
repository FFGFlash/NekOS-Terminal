local App = app.new(...)

App.Input = ""
App.CursorPos = 0
App.InputLine = 1
App.CompletionIndex = 1
App.Completions = {}
App.Config, App.ConfigExists = App:load("options.cfg")

function App:DefineConfig(name, default, validate)
  if self.Config[name] ~= nil and (validate == nil or validate(self.Config[name])) then return end
  self.Config[name] = default
end

App:DefineConfig("UseSystemColors", true)
App:DefineConfig("BackgroundColor", "black", function(val) return colors[val] ~= nil end)
App:DefineConfig("TextColor", "white", function(val) return colors[val] ~= nil end)
App:DefineConfig("AccentColor", "yellow", function(val) return colors[val] ~= nil end)
App:DefineConfig("HighlightBackgroundColor", "white", function(val) return colors[val] ~= nil end)
App:DefineConfig("HighlightTextColor", "black", function(val) return colors[val] ~= nil end)

if not App.ConfigExists then App:save("options.cfg", App.Config) end

App.EventHandler:connect("key", function(key, held)
  if key == keys.backspace then App:updateInput(0)
  elseif key == keys.delete then App:updateInput(1)
  elseif not held then
    if key == keys.enter then App:executeInput()
    elseif key == keys.up then App:changeCompletion(1)
    elseif key == keys.down then App:changeCompletion(-1)
    elseif key == keys.left then App:moveCursor(-1)
    elseif key == keys.right then App:moveCursor(1)
    elseif key == keys.tab then App:updateInput(App.Completions[App.CompletionIndex])
    end
  end
end)

App.EventHandler:connect("paste", function(paste) App:updateInput(paste) end)
App.EventHandler:connect("char", function(char) App:updateInput(char) end)

function App:scroll(change) term.scroll(change) end

function App:changeCompletion(change)
  if not self.Completions then return end
  local max = #self.Completions
  self.CompletionIndex = self.CompletionIndex + change
  if self.CompletionIndex <= 0 then self.CompletionIndex = max
  elseif self.CompletionIndex > max then self.CompletionIndex = 1
  end
end

function App:moveCursor(change)
  self.CursorPos = self.CursorPos + change
  local inLen = string.len(self.Input)
  if self.CursorPos < 0 then self.CursorPos = 0
  elseif self.CursorPos > inLen then self.CursorPos = inLen
  end
end

function App:updateInput(change)
  if type(change) == "number" then
    local charPos = self.CursorPos + change
    self.Input = string.sub(self.Input,1,charPos-1)..string.sub(self.Input,charPos+1,-1)
    if change <= 0 then self:moveCursor(change-1) end
  else
    self.Input = string.sub(self.Input,1,self.CursorPos)..change..string.sub(self.Input,self.CursorPos+1,-1)
    self:moveCursor(string.len(change))
  end
  self.Completions = shell.complete(self.Input)
  self.CompletionIndex = 1
end

function App:executeInput()
  self.Completions = {}
  self.CompletionIndex = 1
  self.CursorPos = 0
  local w,h = term.getSize()
  if self.InputLine + 1 > h then
    self:scroll(h - self.InputLine)
    self.InputLine = self.InputLine - 1
  end
  self:draw()
  term.setCursorBlink(false)
  term.setCursorPos(1,self.InputLine + 1)
  shell.run(self.Input)
  self.Input = ""
  _,self.InputLine = term.getCursorPos()
  term.setCursorBlink(true)
end

function App:writeCompletion()
  if not self.Completions or not self.Completions[self.CompletionIndex] then return end
  local tc,tb = term.getTextColor(), term.getBackgroundColor()
  term.setTextColor(colors[self.Config.HighlightTextColor])
  term.setBackgroundColor(colors[self.Config.HighlightBackgroundColor])
  term.write(self.Completions[self.CompletionIndex])
  term.setTextColor(tc)
  term.setBackgroundColor(tb)
end

function App:draw()
  term.setCursorPos(1,self.InputLine)
  term.setBackgroundColor(self.Config.UseSystemColors and _G.BackgroundColor or colors[self.Config.BackgroundColor])
  term.clearLine()
  term.setTextColor(colors[self.Config.AccentColor])
  term.write(shell.dir())
  term.write("> ")
  term.setTextColor(self.Config.UseSystemColors and _G.TextColor or colors[self.Config.TextColor])
  local x,_ = term.getCursorPos()
  term.write(self.Input)
  self:writeCompletion()
  term.setCursorPos(x + self.CursorPos,self.InputLine)
end

function App:stopped() end

term.setTextColor(App.Config.UseSystemColors and _G.TextColor or colors[App.Config.TextColor])
term.setBackgroundColor(App.Config.UseSystemColors and _G.BackgroundColor or colors[App.Config.BackgroundColor])
term.setCursorPos(1,1)
term.clear()
term.setCursorBlink(true)

App:start()
