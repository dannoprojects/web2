---
title: "Bingo Canvas App"
date: 2021-12-15T06:49:22-08:00
draft: false
theme: Toha
menu:
    sidebar:
        name: PowerApps Bingo
        identifier: powerplatform-bingo
        parent: powerplatform
        weight: 35
hero: images/site/custom-hero.jpg
---


#### Problem
Not really a problem.  Just an interesting mini project.  The office holiday party is a virtual affair this year. Our leadership wanted to play Bingo to give away some extra gifts. Our web filter blocks pretty much anything that would host an online Bingo game, so I knocked out a Bingo Canvas App.
 
#### Solution
- Canvas App based on American Bingo
- Random board is generated each time "New Game" is clicked.
- Tiles change color when clicked to 'mark' the tile.

Screen shot of a new game board.

![The Gameboard](/posts/powerplatform/Bingo/Bingo_1.jpg)

Clicking on a button changes the color from blue to red.  Clicking again changes the color from red to blue.  This allows players to mark or unmark a tile. 

![The Gameboard](/posts/powerplatform/Bingo/Bingo_Selected.jpg)

#### PowerApps Configuration
##### Components
- A series of one column tables for each BINGO letter.
- Formulas to randomize and order the tables.
- Buttons....TOO MANY BUTTONS.

##### Creating the Bingo Values
I had a false start on getting my values for each letter. I thought a collection of random numbers in each letter's range would work.  I could certainly make the collection, but duplicate values were a problem. 

My final solution used single tables.  I did need to do a bit of extra manual work to type out the values in the formula which I could probably do programmatically. 

Here's my formula for setting up my 'B' values. The pattern applies to INGO.

I create the table and continue to reassign it. I could have probably wrapped all of this up in parentheses to make a single line, but I find that difficult to read.

{{< gist dannoprojects 4cbfd2d9820039a1743b316096fc344f "CreateBColumn.txt" >}}

##### Assigning Values to the Buttons
I use Last and FirstN in a formula to slice my table to get the value for each button.  I'm only showing the code for the 'B' values.

{{< gist dannoprojects 4cbfd2d9820039a1743b316096fc344f "ButtonText.txt" >}}

##### Changing the color of the Buttons
Here I use OnSelect and Fill.

{{< gist dannoprojects 4cbfd2d9820039a1743b316096fc344f "Fill.txt" >}}

{{< gist dannoprojects 4cbfd2d9820039a1743b316096fc344f "OnSelect.txt" >}}

##### Future considerations
- I might create an app to generate bingo numbers.  I didn't need to here as the host already has a way getting the numbers.  
- I probably could have handled my buttons actions with less effort.  

##### References
- [American Bingo](https://en.wikipedia.org/wiki/Bingo_(American_version))