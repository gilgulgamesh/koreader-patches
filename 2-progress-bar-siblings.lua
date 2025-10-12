--[[
ReadMes below, to shift the settings higher up. 
note this works on kobo and likely kindle, but
not on android for me.
also only on free-flowing document types. 
]]--

local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Size = require("ui/size")
local Screen = Device.screen
local ReaderView = require("apps/reader/modules/readerview")
local _ReaderView_paintTo_orig = ReaderView.paintTo
local screen_width = Screen:getWidth()
local screen_height = Screen:getHeight()
local ProgressWidget = require("ui/widget/progresswidget")
local UIManager = require("ui/uimanager")

ReaderView.paintTo = function(self, bb, x, y)
    _ReaderView_paintTo_orig(self, bb, x, y)
    if self.render_mode ~= nil then return end -- Show only for epub-likes and never on pdf-likes
--  book info
local pageno = self.state.page or 1 -- Current page
local pages = self.ui.doc_settings.data.doc_pages or 1
local pages_left_book  = pages - pageno
-- chapter info
local pages_chapter = self.ui.toc:getChapterPageCount(pageno) or pages
local pages_left = self.ui.toc:getChapterPagesLeft(pageno) or self.ui.document:getTotalPagesLeft(pageno)
local pages_done = self.ui.toc:getChapterPagesDone(pageno) or 0
pages_done = pages_done + 1 -- This +1 is to include the page you're looking at.
local BOOK_MARGIN = self.document:getPageMargins().left
local CHAPTER = 0
local BOOK = 1
local ON = true
local OFF = false 
--  colour definitions
local pblack  = Blitbuffer.COLOR_BLACK
local pdark   = Blitbuffer.COLOR_GRAY_4
local plight  = Blitbuffer.COLOR_GRAY
local pwhite  = Blitbuffer.COLOR_WHITE

-------------------------------------------------------
     -- -- --  SETTINGS  -- -- --
-------------------------------------------------------
local top_bar_type = CHAPTER -- set as CHAPTER or BOOK
local bottom_bar_type = BOOK -- set as CHAPTER or BOOK
local stacked = OFF -- stacks the top bar on the bottom bar
local margin = 0 -- use BOOK_MARGIN or any numeric value.
local gap = 0 -- gap between progress bars.
local radius = 0 -- make the ends a little round.
local top_padding = -1 -- only for stacked=OFF. negative tucks it in
local prog_bar_height = 7 -- progress bar height.
local bottom_padding = 0 -- space b/w progress bars and bottom edge.
-- "colour" settings        -- you can change the definitions above
local top_bar_fill_color     = pdark
local top_bar_bg_color       = pwhite
local bottom_bar_fill_color  = pblack
local bottom_bar_bg_color    = pwhite

------------------------------------------------------
-- you don't have to change anything below this line.
------------------------------------------------------
screen_width = Screen:getWidth()
screen_height = Screen:getHeight()

local chapter_percentage = pages_done/pages_chapter
local book_percentage = pageno/pages

local top_bar_percentage
local bottom_bar_percentage

local prog_bar_width =  screen_width - gap - margin*2
local prog_bar_y = screen_height - prog_bar_height - bottom_padding

--  compute percentages 
if top_bar_type == CHAPTER then
    top_bar_percentage = chapter_percentage
else
    top_bar_percentage = book_percentage
end

if bottom_bar_type == CHAPTER then
    bottom_bar_percentage = chapter_percentage
else 
    bottom_bar_percentage = book_percentage
end

--  geometry for the bars
local bottom_bar_y    = screen_height - prog_bar_height - bottom_padding    
    
if stacked then
    top_bar_y    = bottom_bar_y - prog_bar_height - gap   
else
    top_bar_y    = top_padding
end
        
--  create the two widgets
local top_bar = ProgressWidget:new{
    width = prog_bar_width,
    height = prog_bar_height,
    percentage = top_bar_percentage,
    margin_v = 0,
    margin_h = 0,
    radius = radius,
    bordersize = 0,
    fillcolor = top_bar_fill_color,
    bgcolor = top_bar_bg_color,
}

local bottom_bar = ProgressWidget:new{
    width = prog_bar_width,
    height = prog_bar_height,
    percentage = bottom_bar_percentage,
    margin_v = 0,
    margin_h = 0,
    radius = radius,
    bordersize = 0,
    fillcolor = bottom_bar_fill_color,
    bgcolor = bottom_bar_bg_color,
}
local bottom_bar_x = Screen:getWidth()/ 2 + gap / 2

top_bar:paintTo(bb, margin, top_bar_y)   
bottom_bar:paintTo(bb, margin, bottom_bar_y)   

end

--[[
Original Preface

i found that chapter ticks on a regular progress bar wasn't for me. i wanted a 
separate progress bar for chapter that also didn't clutter up the ui. so i made this.

**this patch joins two half-sized progress bars end to end 
to make them look like one regular progress bar.*** changed

you can choose what progress (chapter/book) to show on either side and there's
also an option to 'mirror' the progress bars. for eg., chapter progress on both sides
plus mirrored = ON and gap = 0 will essentially give you one regular size progress bar 
that fills from the centre towards the edges.  

you should probably disable the default koreader progress bar and definitely 
uncheck 'auto refresh items' from status bar settings for this to work properly.

this patch works really well on my kindle 4 and kindle basic 2019.

you'll find instructions to configure this patch if you scroll down.

happy reading! =)

CREDITS: some outline code for this was borrowed from a user patch made by 
joshua cantara. (https://github.com/joshuacant/KOReader.patches)



Preface to Second Edition

write up and credit for absolutely everything 
to zenixlabs 
(https://github.com/zenixlabs/koreader-patches)

WARNING this has ai code. this is my first project
I think I understand it all now. 
I don't understand all the original code.
i removed what was unnecessary,
(mirror, inverted) and added stacked vs top of screen

I also renamed the colour variables, renaming the
original pgray and pblack, to plight and
pdark. These are also redefinable to anything.
I then added full white and full black. I
encourage anyone to redefine the colours to customise.
Also swapping the bars still works, although mirror was
removed. I'd love to include options for original twins,
one day. I'd also love to add right to left.

tested on Kobo Libra 2, only noticed conflict with 
bottom status bar. Android not working. And so I can't
test colours that aren't grey
]]--
