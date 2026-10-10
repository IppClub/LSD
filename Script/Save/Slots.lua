local D=require('Dora');local Slots={};Slots.__index=Slots
function Slots.new(directory)
 return setmetatable({directory=directory or D.Content.writablePath},Slots)
end
function Slots:valid(name)
 return name=='lsd.db'or (type(name)=='string'and name:match('^lsd%-journey%-%d+%-%d+%.db$')~=nil)
end
function Slots:list()
 local rows,seen={},{}
 for _,file in ipairs(D.Content:getFiles(self.directory))do
  local name=self:valid(file)and file or file:match('^(.-)%.backup%-%d+%-%d+%.db$')
  if self:valid(name)and not seen[name]then seen[name]=true;rows[#rows+1]=name end
 end
 table.sort(rows,function(a,b)return a>b end)
 return rows
end
function Slots:current()
 local name,why=require('Save.Selection').read(self.directory)
 if why then return nil,why end
 if not name then
  local legacy=D.Path(self.directory,'lsd-current-save.txt')
  if D.Content:exist(legacy)then name=D.Content:load(legacy)end
 end
 if self:valid(name)and D.Content:exist(D.Path(self.directory,name))then return name end
 for _,row in ipairs(self:list())do if D.Content:exist(D.Path(self.directory,row))then return row end end
end
function Slots:attach(name,create)
 if D.DB:existDB('lsd')then return nil,'SAVE_ALREADY_OPEN'end
 if not self:valid(name)then return nil,'INVALID_SAVE'end
 local path=D.Path(self.directory,name)
 if create and D.Content:exist(path)then return nil,'SAVE_EXISTS'end
 if not create and not D.Content:exist(path)then return nil,'SAVE_MISSING'end
 local ok,value=pcall(function()return D.DB:exec("ATTACH DATABASE '"..path:gsub("'","''").."' AS lsd")end)
 if not ok or value<0 then return nil,'SAVE_UNREADABLE'end
 local checkOK,rows=pcall(function()return D.DB:query('PRAGMA lsd.quick_check')end)
 if not checkOK or not rows or not rows[1]or rows[1][1]~='ok'then D.DB:exec('DETACH DATABASE lsd');return nil,'SAVE_UNREADABLE'end
 local compatible,compatibilityError=require('Save.Compatibility').check('lsd')
 if not compatible then D.DB:exec('DETACH DATABASE lsd');return nil,compatibilityError end
 if not create then
  local backup,why=self:backup(name)
  if not backup then D.DB:exec('DETACH DATABASE lsd');return nil,why end
 end
 local saved,why=require('Save.Selection').write(self.directory,name)
 if not saved then D.DB:exec('DETACH DATABASE lsd');return nil,why or 'SELECTION_WRITE_FAILED'end
 return name
end
function Slots:nextName()
 local stamp=tostring(os.time());local i=1;local name
 repeat name='lsd-journey-'..stamp..'-'..i..'.db';i=i+1 until not D.Content:exist(D.Path(self.directory,name))
 return name
end
function Slots:create()return self:attach(self:nextName(),true)end
function Slots:backups(name)
 if not self:valid(name)then return {}end
 local rows={};local prefix=name..'.backup-'
 for _,file in ipairs(D.Content:getFiles(self.directory))do
  if file:sub(1,#prefix)==prefix and file:sub(#prefix+1):match('^%d+%-%d+%.db$')then rows[#rows+1]=file end
 end
 table.sort(rows,function(a,b)
  local at,ai=a:match('backup%-(%d+)%-(%d+)%.db$');local bt,bi=b:match('backup%-(%d+)%-(%d+)%.db$')
  return tonumber(at)==tonumber(bt)and tonumber(ai)>tonumber(bi)or tonumber(at)>tonumber(bt)
 end);return rows
end
function Slots:backup(name)
 local prefix=name..'.backup-'..os.time()..'-';local i=1;local file
 repeat file=prefix..i..'.db';i=i+1 until not D.Content:exist(D.Path(self.directory,file))
 local ok,value=pcall(function()return D.DB:exec("VACUUM lsd INTO '"..D.Path(self.directory,file):gsub("'","''").."'")end)
 if not ok or value<0 then return nil,'BACKUP_FAILED'end
 return file
end
function Slots:restore(name)
 if D.DB:existDB('lsd')then return nil,'SAVE_ALREADY_OPEN'end
 local files=self:backups(name);if not files[1]then return nil,'BACKUP_MISSING'end
 -- Validate before selecting. A bad newer snapshot does not hide older healthy ones.
 local compatibilityError
 for _,file in ipairs(files)do
  local ok,value=pcall(function()return D.DB:exec("ATTACH DATABASE '"..D.Path(self.directory,file):gsub("'","''").."' AS restore_source")end)
  if ok and value>=0 then
   local healthy,rows=pcall(function()return D.DB:query('PRAGMA restore_source.quick_check')end)
   local compatible,why
   if healthy and rows and rows[1]and rows[1][1]=='ok'then compatible,why=require('Save.Compatibility').check('restore_source');compatibilityError=why or compatibilityError end
   if compatible then
    local fresh=self:nextName()
    local copied,result=pcall(function()return D.DB:exec("VACUUM restore_source INTO '"..D.Path(self.directory,fresh):gsub("'","''").."'")end)
    D.DB:exec('DETACH DATABASE restore_source')
    if not copied or result<0 then return nil,'RESTORE_WRITE_FAILED'end
    return self:attach(fresh)
   end
   D.DB:exec('DETACH DATABASE restore_source')
  end
 end
 return nil,compatibilityError or 'BACKUP_UNREADABLE'
end
return Slots
