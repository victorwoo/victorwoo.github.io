layout: post
date: 2017-02-12 16:00:00
title: "PowerShell 技能连载 - Classes (Static Members - Part 6)"
description: PowerTip of the Day - Classes (Static Members - Part 6)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
Classes can define so-called “static” members. Static members (properties and methods) can be invoked by the class itself and do not require an object instance.

Let’s first see an example:

    #requires -Version 5.0
    class TextToSpeech
    {
      # store the initialized synthesizer here
      hidden static $synthesizer
      
      # static constructor, gets called whenever the type is initialized
      static TextToSpeech()
      {
        Add-Type -AssemblyName System.Speech
        [TextToSpeech]::Synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
      }
      
      # convert text to speech
    
      static Speak([string]$text)
      {
        [TextToSpeech]::Synthesizer.Speak($text) 
      }
    }
    

This class “TextToSpeech” encapsulates all that is needed to convert text to speech. It uses a static constructor (which executes when the type is defined) and a static method, so there is no need to instantiate an object. You can use “Speak” immediately:

    # since this class uses static constructors and methods, there is no need
    # to instantiate an object
    [TextToSpeech]::Speak('Hello World!')
    

If you wanted to do the same without “static”, the class would look very similar. You would just need to remove all “static” keywords, and access class properties via $this instead of the type:

    #requires -Version 5.0
    class TextToSpeech
    {
      # store the initialized synthesizer here
      hidden $synthesizer
      
      # static constructor, gets called whenever the type is initialized
      TextToSpeech()
      {
        Add-Type -AssemblyName System.Speech
        $this.Synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
      }
      
      # convert text to speech
    
      Speak([string]$text)
      {
        $this.Synthesizer.Speak($text) 
      }
    }
    

The most significant difference would be on the user side: the user would now have to instantiate an object first:

    $speaker = [TextToSpeech]::new()
    $speaker.Speak('Hello World!')
    

So the thumb of rule is:

* Use “static” members for functionality that only needs to exist once (so a text to speech converter is a good example of a static class) * Use “dynamic” members for functionality that may co-exist in more than one instance (so the user can instantiate as many independent objects as he/she may need).
A class can mix static and dynamic members.

<!--more-->
本文国际来源：[Classes (Static Members - Part 6)](http://community.idera.com/powershell/powertips/b/tips/posts/classes-static-members-part-6)
