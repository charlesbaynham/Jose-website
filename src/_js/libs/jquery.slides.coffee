# SlidesJS 3.0.4

# Documentation and examples http://slidesjs.com
# Support forum http://groups.google.com/group/slidesjs
# Created by Nathan Searles http://nathansearles.com

# Version: 3.0.4
# Updated: June 26th, 2013

# SlidesJS is an open source project, contribute at GitHub:
# https://github.com/nathansearles/Slides

# (c) 2013 by Nathan Searles

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

(($, window, document) ->
  pluginName = "slidesjs"
  defaults =
    width: 940
      # Set the default width of the slideshow.
    height: 528
      # Set the default height of the slideshow.
    start: 1
      # Set the first slide in the slideshow.
    zoom: false
        # [boolean] Resize the images to fill the slider without distorting them
    navigation:
      # Next and previous button settings.
      active: true
        # [boolean] Create next and previous buttons.
        # You can set to false and use your own next/prev buttons.
        # User defined next/prev buttons must have the following:
        # previous: class="slidesjs-previous slidesjs-navigation"
        # next: class="slidesjs-next slidesjs-navigation"
      effect: "slide"
        # [string] Can be either "slide" or "fade".
      rollover: true
        # [boolean] "Next" on final slide goes back to first
    pagination:
        # Pagination settings
      active: true
        # [boolean] Create pagination items.
      effect: "slide"
        # [string] Can be either "slide" or "fade".
      generate: true
        # [boolean] Generate pagination nav. If false, search for a
        #     ul.slidesjs-navigation.slidesjs-pagination > li > a 
        #   structure.
    play:
        # Play and stop button setting.
      active: false
        # [boolean] Enable hands-free playing of slideshow.
      generate: true
        # [boolean] Create play and stop button.
        # You can set to false and use your own play/stop buttons.
        # User defined play/stop buttons must have the following:
        # play: class="slidesjs-play slidesjs-navigation"
        # stop: class="slidesjs-stop slidesjs-navigation"
      effect: "slide"
        # [string] Can be either "slide" or "fade".
      interval: 5000
        # [number] Time spent on each slide in milliseconds.
      auto: false
        # [boolean] Start playing the slideshow on load
      swap: true
        # [boolean] show/hide stop and play buttons
      pauseOnHover: false
        # [boolean] pause a playing slideshow on hover
      restartDelay: 2500
        # [number] restart delay on an inactive slideshow
    effect:
      slide:
        # Slide effect settings.
        speed: 500
          # [number] Speed in milliseconds of the slide animation.
        easing: "ease"
          # [string] The CSS3 easing to use, if supported. 
          # Choose: ease|linear|ease-in|ease-out|ease-in-out|cubic-bezier(n,n,n)|initial|inherit
        jsEasing: "swing"
          # [string] The fallback jquery easing, used when CSS3 is not supported
      fade:
        speed: 300
          # [number] Speed in milliseconds of the fade animation.
        crossfade: true
          # [boolean] Cross-fade the transition
    callback:
      loaded: () ->
        # [function] Called when slides is loaded
      start: () ->
        # [function] Called when animation has started
      complete: () ->
        # [function] Called when animation is complete
    lazy: false
      # [boolean] Don't load the images until they're needed. To use this, set the
      #           img element's src as "" or a placeholder, and add the actual src
      #           as a data-original="..." attribute
      
    # [string] Data to use instead of an image if the image isn't loaded. A gray square by default
    lazyPlaceholder: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC"

  class Plugin
    constructor: (@element, options) ->
      @options = $.extend true, {}, defaults, options
      @_defaults = defaults
      @_name = pluginName
      @_random = Math.random()
      @init()

  Plugin::init = ->
    $element = $(@element)
    @data = $.data this
    
    # Save placeholder into window data
    window["lazyPlaceholder_#{@_name}#{@_random}"] = @options.lazyPlaceholder
    
    # Set data
    $.data this, "animating", false
    $.data this, "total", $element.children().not(".slidesjs-navigation", $element).length
    $.data this, "current", @options.start - 1
    $.data this, "vendorPrefix", @_getVendorPrefix()

    # Detect touch device
    if typeof TouchEvent != "undefined"
      $.data this, "touch", true
      # Set slide speed to half for touch
      @options.effect.slide.speed = this.options.effect.slide.speed / 2

    # Hide overflow
    $element.css overflow: "hidden"

    # Create container
    $element.slidesContainer = $element.children().not(".slidesjs-navigation", $element).wrapAll("<div class='slidesjs-container'>", $element).parent().css
      overflow: "hidden"
      position: "relative"

    # Create control div
    $(".slidesjs-container", $element)
    .wrapInner("<div class='slidesjs-control'>", $element)
    .children()

    # Setup control div
    $(".slidesjs-control", $element)
    .css
      position: "relative"
      left: 0

    # Setup slides
    $(".slidesjs-control", $element)
    .children()
    .addClass("slidesjs-slide")
    .css
      position: "absolute"
      top: 0
      left: 0
      width: "100%"
      zIndex: 0
      display: "none"
      webkitBackfaceVisibility: "hidden"

    # Assign an index to each slide
    $.each( $(".slidesjs-control", $element).children(), (i) ->
      $slide = $(this)
      $slide.attr("slidesjs-index", i)
    )

    if @data.touch
      # Bind touch events, if supported
      $(".slidesjs-control", $element).on("touchstart", (e) =>
        @_touchstart(e)
      )

      $(".slidesjs-control", $element).on("touchmove", (e) =>
        @_touchmove(e)
      )

      $(".slidesjs-control", $element).on("touchend", (e) =>
        @_touchend(e)
      )

    # Fades in slideshow, your slideshow ID must be display:none in your CSS
    $element.fadeIn 0

    # Update sets width/height of slideshow
    @update()
    
	# Zoom the image so that it fills the slider without distortion if the option is set
    if @options.zoom
      @_zoom()

    # If touch device setup next slides
    @_setuptouch() if @data.touch

    # Fade in start slide
    $(".slidesjs-control", $element)
    .children(":eq(" + @data.current + ")")
    .eq(0)
    .fadeIn 0, ->
      $(this).css zIndex: 10

    if @options.navigation.active
      # Create next/prev buttons
      prevButton = $("<a>"
        class: "slidesjs-previous slidesjs-navigation"
        href: "#"
        title: "Previous"
        text: "Previous"
      ).appendTo($element)

      nextButton = $("<a>"
        class: "slidesjs-next slidesjs-navigation"
        href: "#"
        title: "Next"
        text: "Next"
      ).appendTo($element)

    # bind click events
    $(".slidesjs-next", $element).click (e) =>
      e.preventDefault()
      @stop(true)
      @next(@options.navigation.effect)

    $(".slidesjs-previous", $element).click (e) =>
      e.preventDefault()
      @stop(true)
      @previous(@options.navigation.effect)

    if @options.play.active
    # If slideshow active
      
      if @options.play.generate
      # Generate play / stop button
          playButton = $("<a>",
            class: "slidesjs-play slidesjs-navigation"
            href: "#"
            title: "Play"
            text: "Play"
          ).appendTo($element)
      
          stopButton = $("<a>",
            class: "slidesjs-stop slidesjs-navigation"
            href: "#"
            title: "Stop"
            text: "Stop"
          ).appendTo($element)
      
      else
      # Search for user's play/stop buttons
          playButton = $(".slidesjs-play.slidesjs-navigation", $element)
          stopButton = $(".slidesjs-stop.slidesjs-navigation", $element)
      

      playButton.click (e) =>
        e.preventDefault()
        @play(true)

      stopButton.click (e) =>
        e.preventDefault()
        @stop(true)

      if @options.play.swap
        stopButton.css
          display: "none"


    if @options.pagination.active
      
      if @options.pagination.generate
        # Create unordered list pagination
        pagination = $("<ul>"
          class: "slidesjs-pagination"
        ).appendTo($element)

        # Create a list item and anchor for each slide
        $.each(new Array(@data.total), (i) =>
          paginationItem = $("<li>"
            class: "slidesjs-pagination-item"
          ).appendTo(pagination)

          paginationLink = $("<a>"
            href: "#"
            "data-slidesjs-item": i
            html: i + 1
          ).appendTo(paginationItem)

          # bind click events
          paginationLink.click (e) =>
            e.preventDefault()
            # Stop play
            @stop(true)
            # Goto to selected slide
            @goto( ($(e.currentTarget).attr("data-slidesjs-item") * 1) + 1 )
        )
      else
        paginationLIs = $('.slidesjs-pagination li', $element)
        
        paginationLIs.each (i) =>
          
          # For each link already there, add the index
          paginationLIs.eq(i)
            .data("slidesjs-item", i)
          # and bind click events
            .click (e) =>
              e.preventDefault()
              # Stop play
              @stop(true)
              # Goto to selected slide
              @goto( ($(e.currentTarget).data("slidesjs-item") * 1) + 1 )

    # If lazy loading is enabled, give all the images without a src a gray placeholder
    if @options.lazy
        # Get all img slides & all first images in div slides
        $("img.slidesjs-slide, .slidesjs-slide img:first-of-type", $element).each ->
            
            if @src == ""
                @src = window["lazyPlaceholder_#{@_name}#{@_random}"]
    
    # Bind update on browser resize
    $(window).bind("resize", () =>
      @update()
    )

    # Set start pagination item to active
    @_setActive()

    # Auto play slideshow
    if @options.play.auto
      @play()
      
    # If we're on the first or last slides and rollover is off, remove the appropriate arrow
    # Otherwise show both
    @_hideNavArrows() unless @options.navigation.rollover

    # Slides has loaded
    @options.callback.loaded(@options.start)

  # @_setActive()
  # Sets the active slide in the pagination & loads its image if not already loaded
  Plugin::_setActive = (number) ->
    $element = $(@element)
    @data = $.data this

    # Get the current slide index
    current = if number > -1 then number else @data.current

    # Set active slide in pagination
    $(".active", $element).removeClass "active"
    $(".slidesjs-pagination li:eq(" + current + ") a", $element).addClass "active"
    
    # Lazy load this image and the next one if enabled
    if @options.lazy
        
        # Get the slide's image
        $slide = $(".slidesjs-control", $element).children().eq(current)
        $img = if $slide.is("img") then $slide else $slide.find("img:first")
        
        if not $img.data("loaded")
          @_lazyLoad($img)
            
        # Get the next slide's image
        $slide = $(".slidesjs-control", $element).children().eq(current+1)
        $img = if $slide.is("img") then $slide else $slide.find("img:first")
        
        if $img.length != 0 and not $img.data("loaded")
          @_lazyLoad($img)
  
  # @_lazyLoad(img_element)
  # Loads the original image for the given element and then replaces the currently shown placeholder
  # with the newly loaded image
  Plugin::_lazyLoad = (img) ->
    
    $img = $(img)
    
    # Actual src
    src = $img.data("original")
  
    # Create an img element to load the image so that the browser has it in the cache
    $('<img />')
        # When this virtual img is loaded, set the slideshow's src to the same so that we see it
        .one "load.#{@_name}", =>
            $img.attr "src", src
        # Actually do the loading
        .attr "src", src
  
    # Flag as loaded
    $img.data("loaded", true)

  # @_zoom()
  # Resizes the children images of the slider so that they fill the slider without being distorted
  Plugin::_zoom = ->
    $element = $(@element)
    @data = $.data this
	
    # The aspect ratio of the parent container
    targetRatio = @options.width  / @options.height
    
    # Set any children divs to full size so that the subsequent resizing of their images works
    $(".slidesjs-control", $element).children("div").css
        width: "100%",
        height: "100%"
    
    # The children images
    img = $(".slidesjs-control", $element).find("img, div img:first")
    
    
    # Register the function to zoom each image as soon as it's loaded
    img.each ->
        $(this).on "load", ->
            $img = $(this)
            
            imgWidth = this.naturalWidth
            imgHeight = this.naturalHeight
            
            # The aspect ratio of this child img
            imgRatio = imgWidth / imgHeight
            
            # A max width / height will cause manual resizing to fail, so we remove it if present. 
            $img.css
                "max-width": "none",
                "max-height": "none"
            
            # If the image is wider than the container, set it to fill the container's height and overflow by width
            # Also set the margins so that the image is centered
            if imgRatio > targetRatio
                # Calculate half the amount by which the image is wider than the container as a percentage OF THE CONTAINER'S WIDTH
                overflow = (imgRatio / targetRatio - 1) * 100 / 2
                
                $img.css
                    height: "100%",
                    width: "auto",
                    margin: "0 0 0 -" + overflow + "%"
                    
            # Vice versa for the other case (taller than container)        
            else
                # Calculate half the amount by which the image is taller than the container as a percentage OF THE CONTAINER'S WIDTH
                overflow = (1 / imgRatio - 1 / targetRatio) * 100 / 2
                
                $img.css
                    height: "auto",
                    width: "100%",
                    margin: "-" + overflow + "% 0 0 0"
            
        # If the image was already loaded by the time this code runs, trigger the "load" handler now    
        if this.complete || this.naturalWidth != 0
            $(this).trigger "load"

  # @resize(width, height)
  # Resize the slidershow to a new width and height
  Plugin::resize = (width, height) ->
  
    # Set height and width in options
    @options.width = width
    @options.height = height
    
    # Refresh display
    @update()
    if @options.zoom
      @_zoom()
    
    @
      
  # @changeOptions(newOptions)
  # Merge an options object, altering the currently set options. 
  Plugin::changeOptions = (newOptions) ->
    @options = $.extend true, {}, @options, newOptions
    @
  
  # @update()
  # Update the slideshow size on browser resize
  Plugin::update = ->
    $element = $(@element)
    @data = $.data this

    # Hide all slides expect current
    $(".slidesjs-control", $element).children(":not(:eq(" + @data.current + "))").css
      display: "none"
      left: 0
      zIndex: 0

    # Get the new width and height
    width = $element.width()
    height = (@options.height / @options.width) * width

    # Store new width and height
    @options.width = width
    @options.height = height

    # Set new width and height
    $(".slidesjs-control, .slidesjs-container", $element).css
      width: width
      height: height

  # @next()
  # Next mechanics
  Plugin::next = (effect) ->
    $element = $(@element)
    @data = $.data this

    # Set the direction
    $.data this, "direction", "next"

    # Slides or fade effect
    if effect is undefined then effect = @options.navigation.effect
    if effect is "fade" then @_fade() else @_slide()

  # @previous()
  # Previous mechanics
  Plugin::previous = (effect) ->
    $element = $(@element)
    @data = $.data this

    # Set the direction
    $.data this, "direction", "previous"

    # Slides or fade effect
    if effect is undefined then effect = @options.navigation.effect
    if effect is "fade" then @_fade() else @_slide()

  # @goto()
  # Pagination mechanics
  Plugin::goto = (number) ->
    $element = $(@element)
    @data = $.data this

    # Set effect to default if not defined
    if effect is undefined then effect = @options.pagination.effect

    # Error correction if slide doesn't exists
    if number > @data.total
      number = @data.total
    else if number < 1
      number = 1

    if typeof number is "number"
      if effect is "fade" then @_fade(number) else @_slide(number)
    else if typeof number is "string"
      if number is "first"
        if effect is "fade" then @_fade(0) else @_slide(0)
      else if number is "last"
        if effect is "fade" then @_fade(@data.total) else @_slide(@data.total)

  # @_setuptouch()
  # Setup slideshow for touch
  Plugin::_setuptouch = () ->
    $element = $(@element)
    @data = $.data this

    # Define slides control
    slidesControl = $(".slidesjs-control", $element)

    # Get next/prev slides around current slide
    next = @data.current + 1
    previous = @data.current - 1

    # Create the loop
    previous = @data.total - 1 if previous < 0
    next = 0 if next > @data.total - 1

    # By default next/prev slides are hidden, show them when on touch device
    slidesControl.children(":eq(" + next + ")").css
      display: "block"
      left: @options.width

    slidesControl.children(":eq(" + previous + ")").css
      display: "block"
      left: -@options.width

  # @_touchstart()
  # Start touch
  Plugin::_touchstart = (e) ->
    $element = $(@element)
    @data = $.data this
    touches = e.originalEvent.touches[0]

    # Setup the next and previous slides for swiping
    @_setuptouch()

    # Start touch timer
    $.data this, "touchtimer", Number(new Date())

    # Set touch position
    $.data this, "touchstartx", touches.pageX
    $.data this, "touchstarty", touches.pageY

    # Stop event from bubbling up
    e.stopPropagation()

  # @_touchend()
  # Animates the slideshow when touch is complete
  Plugin::_touchend = (e) ->
    $element = $(@element)
    @data = $.data this
    touches = e.originalEvent.touches[0]

    # Define slides control
    slidesControl = $(".slidesjs-control", $element)

    # Slide has been dragged to the right & we're not at the limit/rollover is enabled: goto previous slide
    if ( slidesControl.position().left > @options.width * 0.5 || slidesControl.position().left > @options.width * 0.1 && (Number(new Date()) - @data.touchtimer < 250) ) && ( @data.current != 0 || @options.navigation.rollover )
      $.data this, "direction", "previous"
      @_slide()
    # Slide has been dragged to the left & we're not at the limit/rollover is enabled: goto next slide
    else if ( slidesControl.position().left < -(@options.width * 0.5) || slidesControl.position().left < -(@options.width * 0.1) && (Number(new Date()) - @data.touchtimer < 250) ) && ( @data.current != @data.total-1 || @options.navigation.rollover )
      $.data this, "direction", "next"
      @_slide()
    else
      # Slide has not been dragged far enough, animate back to 0 and reset
        # Get the browser's vendor prefix
        prefix = @data.vendorPrefix

        # Create CSS3 styles based on vendor prefix
        transform = prefix + "Transform"
        duration = prefix + "TransitionDuration"
        timing = prefix + "TransitionTimingFunction"

        # Set CSS3 styles
        slidesControl[0].style[transform] = "translateX(0px)"
        slidesControl[0].style[duration] = @options.effect.slide.speed * 0.85 + "ms"

    # Rest slideshow
    slidesControl.on "transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd", =>
        # Get the browser's vendor prefix
        prefix = @data.vendorPrefix

        # Create CSS3 styles based on vendor prefix
        transform = prefix + "Transform"
        duration = prefix + "TransitionDuration"
        timing = prefix + "TransitionTimingFunction"

        # Set CSS3 styles
        slidesControl[0].style[transform] = ""
        slidesControl[0].style[duration] = ""
        slidesControl[0].style[timing] = ""

    # Stop event from bubbling up
    e.stopPropagation()

  # @_touchmove()
  # Moves the slide on touch
  Plugin::_touchmove = (e) ->
    $element = $(@element)
    @data = $.data this
    touches = e.originalEvent.touches[0]

    # Get the browser's vendor prefix
    prefix = @data.vendorPrefix

    # Define slides control
    slidesControl = $(".slidesjs-control", $element)

    # Create CSS3 styles based on vendor prefix
    transform = prefix + "Transform"

    # Check if user is trying to scroll vertically
    $.data this, "scrolling", Math.abs(touches.pageX - @data.touchstartx) < Math.abs(touches.pageY - @data.touchstarty)

    # Set CSS3 styles
    if !@data.animating && !@data.scrolling
      # Prevent default scrolling
      e.preventDefault()
      @_setuptouch()
      slidesControl[0].style[transform] = "translateX(" + (touches.pageX - @data.touchstartx) + "px)"

    # Stop event from bubbling up
    e.stopPropagation()

  # @play()
  # Play the slideshow
  Plugin::play = (next) ->
    $element = $(@element)
    @data = $.data this

    # Check if the slideshow is already playing
    if not @data.playInterval
      # If next is true goto next slide
      if next
        currentSlide = @data.current
        @data.direction = "next"
        if @options.play.effect is "fade" then @_fade() else @_slide()

      # Set and store interval
      $.data this, "playInterval", setInterval ( =>
        currentSlide = @data.current
        @data.direction = "next"
        if @options.play.effect is "fade" then @_fade() else @_slide()
      ), @options.play.interval

      # Define slides container
      slidesContainer = $(".slidesjs-container", $element)

      if @options.play.pauseOnHover
        # Prevent event build up
        slidesContainer.unbind()

        # Stop/pause slideshow on mouse enter
        slidesContainer.bind "mouseenter", =>
          clearTimeout @data.restartDelay
          $.data this, "restartDelay", null
          @stop()

        # Play slideshow on mouse leave
        slidesContainer.bind "mouseleave", =>
          if @options.play.restartDelay
            $.data this, "restartDelay", setTimeout ( =>
              @play(true)
            ), @options.play.restartDelay
          else
            @play()

      $.data this, "playing", true

      # Add "slidesjs-playing" class to "slidesjs-play" button
      $(".slidesjs-play", $element).addClass("slidesjs-playing")

      if @options.play.swap
        $(".slidesjs-play", $element).hide()
        $(".slidesjs-stop", $element).show()

  # @stop()
  # Stops a playing slideshow
  Plugin::stop = (clicked) ->
    $element = $(@element)
    @data = $.data this

    # Clear play interval
    clearInterval @data.playInterval

    if @options.play.pauseOnHover && clicked
      # Prevent event build up
      $(".slidesjs-container", $element).unbind()

    # Reset slideshow
    $.data this, "playInterval", null
    $.data this, "playing", false
    $(".slidesjs-play", $element).removeClass("slidesjs-playing")

    if @options.play.swap
      $(".slidesjs-stop", $element).hide()
      $(".slidesjs-play", $element).show()

  # @_slide()
  # CSS3 and JavaScript slide animations
  Plugin::_slide = (number) ->
    $element = $(@element)
    @data = $.data this

    if not @data.animating and number isnt @data.current + 1
      # Set animating to true
      $.data this, "animating", true

      # Get current slide
      currentSlide = @data.current

      if number > -1
        number = number - 1
        value = if number > currentSlide then 1 else -1
        direction = if number > currentSlide then -@options.width else @options.width
        next = number
      else
        value = if @data.direction is "next" then 1 else -1
        direction = if @data.direction is "next" then -@options.width else @options.width
        next = currentSlide + value

      # Loop from first to last slide
      next = @data.total - 1 if next is -1

      # Loop from last to first slide
      next = 0 if next is @data.total

      # Set next slide pagination item to active
      @_setActive(next)

      # Define slides control
      slidesControl = $(".slidesjs-control", $element)

      # When changing from touch to pagination reset touch slide setup
      if number > -1
        # Hide all slides expect current
        slidesControl.children(":not(:eq(" + currentSlide + "))").css
          display: "none"
          left: 0
          zIndex: 0

      # Setup the next slide
      slidesControl.children(":eq(" + next + ")").css
        display: "block"
        left: value * @options.width
        zIndex: 10

      # Start the slide animation
      @options.callback.start(currentSlide + 1)

      if @data.vendorPrefix
        # If supported use CSS3 for the animation
        # Get the browser's vendor prefix
        prefix = @data.vendorPrefix

        # Create CSS3 styles based on vendor prefix
        transform = prefix + "Transform"
        duration = prefix + "TransitionDuration"
        timing = prefix + "TransitionTimingFunction"

        # Set CSS3 styles
        slidesControl[0].style[transform] = "translateX(" + direction + "px)"
        slidesControl[0].style[duration] = @options.effect.slide.speed + "ms"
        slidesControl[0].style[timing] = @options.effect.slide.easing

        slidesControl.on "transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd", =>
          # Clear styles
          slidesControl[0].style[transform] = ""
          slidesControl[0].style[duration] = ""

          # Reset slideshow
          slidesControl.children(":eq(" + next + ")").css left: 0
          slidesControl.children(":eq(" + currentSlide + ")").css
            display: "none"
            left: 0
            zIndex: 0

          # Set the new slide to the current
          $.data this, "current", next

          # # Set animating to false
          $.data this, "animating", false

          # Unbind transition callback to prevent build up
          slidesControl.unbind("transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd")

          # Hide all slides expect current
          slidesControl.children(":not(:eq(" + next + "))").css
            display: "none"
            left: 0
            zIndex: 0
            
          # If we're on the first or last slides and rollover is off, remove the appropriate arrow
          # Otherwise show both
          @_hideNavArrows() unless @options.navigation.rollover
              
          # If touch device setup next slides
          @_setuptouch() if @data.touch

          # End of the animation, call complete callback
          @options.callback.complete(next + 1)
      else
        # If CSS3 isn't support use JavaScript for the animation
        slidesControl.stop().animate
          left: direction
        , @options.effect.slide.speed, @options.effect.slide.jsEasing, (=>
          slidesControl.css left: 0
          slidesControl.children(":eq(" + next + ")").css left: 0
          slidesControl.children(":eq(" + currentSlide + ")").css
            display: "none"
            left: 0
            zIndex: 0

            # Set the new slide to the current
            $.data this, "current", next
            
            # If we're on the first or last slides and rollover is off, remove the appropriate arrow
            # Otherwise show both
            @_hideNavArrows() unless @options.navigation.rollover
            
            # Set animating to false
            $.data this, "animating", false

            # End of the animation, call complete callback
            @options.callback.complete(next + 1)
          )

  # @_fade()
  # Fading and cross fading
  Plugin::_fade = (number) ->
    $element = $(@element)
    @data = $.data this

    # Check if not currently animating and the selected slide is not the current slide
    if not @data.animating and number isnt @data.current + 1

      # Set animating to true
      $.data this, "animating", true

      # Get current slide
      currentSlide = @data.current

      if number
        # Specific slide has been called
        number = number - 1
        value = if number > currentSlide then 1 else -1
        next = number
      else
        # Next/prev slide has been called
        value = if @data.direction is "next" then 1 else -1
        next = currentSlide + value

      # Loop from first to last slide
      next = @data.total - 1 if next is -1

      # Loop from last to first slide
      next = 0 if next is @data.total

      # Set next slide pagination item to active
      @_setActive next

      # Define slides control
      slidesControl = $(".slidesjs-control", $element)

      # Setup the next slide
      slidesControl.children(":eq(" + next + ")").css
        display: "none"
        left: 0
        zIndex: 10

      # Start of the animation, call the start callback
      @options.callback.start(currentSlide + 1)

      if @options.effect.fade.crossfade
        # Fade out current slide to next slide
        slidesControl.children(":eq(" + @data.current + ")")
        .stop()
        .fadeOut @options.effect.fade.speed

        # Fade in to next slide
        slidesControl.children(":eq(" + next + ")")
        .stop()
        .fadeIn @options.effect.fade.speed, (=>
          # Reset slides
          slidesControl.children(":eq(" + next + ")").css zIndex: 0

          # Set animating to false
          $.data this, "animating", false

          # Set the new slide to the current
          $.data this, "current", next
          
          # If we're on the first or last slides and rollover is off, remove the appropriate arrow
          # Otherwise show both
          @_hideNavArrows() unless @options.navigation.rollover

          # End of the animation, call complete callback
          @options.callback.complete(next + 1)
        )
      else
        # Fade to next slide
        slidesControl.children(":eq(" + currentSlide + ")")
        .stop()
        .fadeOut @options.effect.fade.speed, (=>
          # Reset slides
          slidesControl.children(":eq(" + next + ")")
          .stop()
          .fadeIn @options.effect.fade.speed, (=>
            # Reset slides
            slidesControl.children(":eq(" + next + ")").css zIndex: 10
          )

          # Set animating to false
          $.data this, "animating", false

          # Set the new slide to the current
          $.data this, "current", next
          
          # If we're on the first or last slides and rollover is off, remove the appropriate arrow
          # Otherwise show both
          @_hideNavArrows() unless @options.navigation.rollover

          # End of the animation, call complete callback
          @options.callback.complete(next + 1)
        )
        
  # @_hideNavArrows()
  # Hides the nav arrows if we're on the first or last slide & shows them otherwise
  Plugin::_hideNavArrows = () ->
    $element = $(@element)
    
    leftArrow = $(".slidesjs-previous", $element)
    rightArrow = $(".slidesjs-next", $element)
    
    if @data.current == 0
      leftArrow.hide()
      rightArrow.show()
    else if @data.current == @data.total - 1
      rightArrow.hide()
      leftArrow.show()
    else
      rightArrow.show()
      leftArrow.show()  

  # @_getVendorPrefix()
  # Check if the browser supports CSS3 Transitions
  Plugin::_getVendorPrefix = () ->
    body = document.body or document.documentElement
    style = body.style
    transition = "transition"

    vendor = ["Moz", "Webkit", "Khtml", "O", "ms"]
    transition = transition.charAt(0).toUpperCase() + transition.substr(1)

    i = 0

    while i < vendor.length
      return vendor[i] if typeof style[vendor[i] + transition] is "string"
      i++
    false

  # Plugin constructor
  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(@, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new Plugin(@, options))

)(jQuery, window, document)
