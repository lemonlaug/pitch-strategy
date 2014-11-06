Pitching Strategy Analytics
===========================

Introduction to PitchFx
---------------------------

Using tracking equipment installed in every major leagues stadium, baseball is now able to provide incredibly detailed data on every single pitch thrown during the big league season.

A lot of the existing work has focused on understsanding the strike zone...

Pitching Strategy
---------------------------

In game seven of the world series, with the tying run on third base and two outs Salvador Perez faced Madison Bumgarner with the game on the line. Bumgarner threw six straight high fastballs out of the strikezone. 

![Chart of Bumgarner vs. Perez](plots/perez_v_bumgarner.png)

This is an unusual strategy to put it mildly. Only one of the six pitches was (barely) in the zone, and besides differences in how far in or out the pitches were, there was hardly any variation in speed, or pitch selection. Nonetheless, this approach was successful when Perez popped weakly in foul territory to end the game. In the postgame interview, Bumgarner uncharacteristically revealed his strategy.

> I knew Perez was going to want to do something big... We tried to use that aggressiveness and throw our pitches up in the zone. It's a little bit higher than high, I guess, and fortunately I was able to get some past him.

So in this case, Bumgarner knew his opponents tendencies and the psychology against him masterfully, getting an out, without throwing a ball that it was possible to put in play.

Such strategic concerns are an underexplored application of PitchFx data. Each at-bat is of course not only a sequence of independent pitches, but in fact a whole strategic game between pitcher and batter. Conventional wisdom says that pitchers are most effective when changing speeds, and forcing the hitter to change his eye level by working inside and outside, and up and down in the zone.

Both the pitcher and batter try to anticipate each others' expectations in order to guess (hitter) or defy expectations (pitcher) of their adversary. Because of this strategic element, the game theory is extremely rich, and pitchers and batters presumably exploit all kinds of information to try and gain an edge in this strategic battle. This information may include, previous at bats against a given adversary, previous pitches in the current at bat, the pitcher's strategy against other hitters.

Modeling
---------------------------
This repository contains some preliminary attempts to create a data set useful for modeling pitching strategy. We begin by creating a data set that includes all pitches and the preceding pitches. Using the characteristics of these pitches, the pitch type, location, speed etc. We then train a small (maximum depth of 4) decision tree to classify the expected outcomes of these pitches. Even this basic model is able to reveal much of the "conventional wisdom" about pitching strategy. First, seeing what variables the model chooses to segment on is instructive, the count, whether the batter swung on the previous pitch, the pitch type, the height of the pitch all appear in this simple tree. See the outcomes below, which describe the outcomes for all pitches where the batter did not swing at the previous pitch. Notice, that the decision tree is able to sensibly group outcomes according to count, two-strike counts (except 0-2) are treated differently than other counts, breaking pitches are identified as having different outcomes from fastballs (with the exception of a few uncommon pitches like EP (eephus pitch)). Finally, in the final distribution of outcomes, note that throwing a breaking ball in these counts is about twice as likely to result in a swinging strike than is throwing a fastball. Fastballs on the other hand are more likely to result in called strikes.

![Chart of decision tree](img/tree_branch1.png)

On the other side of the chart, in the third leaf of the tree, notice that in the more hitter friendly counts of 1-1 and 2-1 (0-2 is included here also), called strikes are much more likely, as hitters presumably wait for something that's more favorable to them. Again, breaking pitches are more likely to result in swinging strikes and less likely to be contacted either foul or in play.

Of course, that this should match the conventional wisdom is not surprising. If pitchers are coached to pitch a particular way in particular counts, then we would expect to seem them doing that. So this analysis tells us what pitchers are doing, not necessarily what they should do. Answering the quesiton of what strategy is optimal requires a little more thought still.


What Else To Do
----------------------------

Looking at the overall average is only of limited interest, of greater interest would be to try identify the strategic tendencies or abilties of individual pitchers/hitters. Even better would be to try to predict which matchups might be favorable for one side or another, this kind of information could be very useful to managers who have to set lineups and make in-game decisions. The data for any particular matchup is undoubtedly too sparse to model directly, but it may be possible to predict the pair using individual pitcher/hitter models where there would be more data.

A couple items that further analysis of this data could try to address:
  * Strategy, is it the catcher or the pitcher?
  * Can we identify players who especially excel at strategy (are more successful than their we would predict given only their individual pitches in isolation)?
  * Can we identify matchups that are especially favorable for one side or another based on the strategy + abilities of the pitcher?