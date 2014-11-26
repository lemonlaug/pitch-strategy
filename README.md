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

This is an unusual strategy to put it mildly. Only one of the six pitches was (barely) in the zone, and besides differences in how far in or out the pitches were, there was hardly any variation in speed, or pitch selection. Nonetheless, this approach was successful when Perez popped up weakly in foul territory to end the game. In the postgame interview, Bumgarner uncharacteristically revealed his strategy.

> I knew Perez was going to want to do something big... We tried to use that aggressiveness and throw our pitches up in the zone. It's a little bit higher than high, I guess, and fortunately I was able to get some past him.

In this case, Bumgarner knew his opponents tendencies and the psychology of the moment and used that knowledge against him masterfully to get an out without throwing a ball that it was possible to put in play.

Such strategic concerns are an underexplored application of PitchFx data. Each at-bat is not only a sequence of independent pitches, but in fact a whole strategic game between pitcher and batter, which may extend back years. Conventional wisdom says that pitchers are most effective when changing speeds, and forcing the hitter to change his eye level by working inside and outside, and up and down in the zone.

Both the pitcher and batter try to anticipate each others' expectations in order to guess (hitter) or defy (pitcher) expectations of their adversary. Because of this strategic element, the game theory is extremely rich, and pitchers and batters presumably exploit all kinds of information to try and gain an edge in this strategic battle. This information may include, previous at bats against a given adversary, previous pitches in the current at bat, the pitcher's strategy against other hitters.

Modeling
---------------------------
This repository contains some preliminary attempts to create a data set useful for modeling pitching strategy. We begin by creating a data set that includes all pitches and the pitches that preceded them. To begin with, we do a little modeling to show the differences among pitches in how to get a swinging strike.

![Swinging Strike Probabilities](plots/swinging_k_by_pitch_type.png)

In the above chart, we plot the probability density of a swinging strike for four different pitches based on the location of the pitch in righty vs. righty scenarios. Not surprisingly, there are big differences here: breaking balls are more effective low in the zone, whereas fourseam fastballs are effective high in the zone. All pitches have a kind of halo around the plate, getting swinging strikes on pitches in the heart of the plate is unlikely, but more likely for changeups, and curveballs, which may be due to the fact that these pitches rely more on speed changes than location to deceive the hitter.

But what is the effect of strategy? How does this story change based on setups? We can model this by looking at the difference between the overall probability densities and the probability densities associated with a particular setup pitch.

![Effect of Setup Pitches on Strike Probabilities](plots/swinging_k_by_pitch_type_setup.png)

The columns of this grid represent the "last" pitch, and the rows represent the preceding pitch. Comparing the columns shows how different setup pitches affect the likelihood of a strike for the pitch in that row. While these absolute levels are important, because a pitcher cares about throwing the absolute most effective pitch, it's also interesting to look at the difference between the general behavior and the "set up" behavior, because it tells us something about the strategic game being played between hitter and pitcher.

![Change in swinging strike probabilities by setup.](plots/difference_swinging_k_by_pitch_type_setup.png)

In this view, the importance of speed would seem to become more apparent. For example, you're slightly more likely to get a swing and miss on a changeup in the zone, if you set it up with a slider. Sliders and fastballs outside the zone are more effective when setup by a changeup.

We can do a similar exercise for called strikes, to see if there's any evidence for strategic thinking as far as called strikes go. There are fewer called strikes overall, and as we'll see, the overall evidence for setting up a batter for a called strike ("freezing them") isn't strong (at least, not on the basis of pitch selection alone).

![Effect of setup pitches on called strike probabilities](plots/called_k_by_pitch_type_setup.png)

In this chart, aside from some obvious data sparsity issues, note, there's not much difference within the columns, meaning pretty much that the pitcher has to get it in the halo around the edges of the strikezone to get a called strike, and once that's accomplished, what the last pitch was doesn't make much difference by itself (this is a case where changing locations, moving up/down in/out, might be more important than pitch-selection alone.

What Else To Do
----------------------------

Ultimately a fully comprehensive model should control for handedness of batter and pitcher, count, pitch quality (e.g. break, speed), changes in speed, and individual batter and pitcher characteristics. With such a model in hand, it might be possible to score how lucky or unlucky pitchers are. By seeing which pitchers have the greatest difference between observed and expected outcomes, we might be able to quantify the extent to which pitchers are experiencing a stretch of good or bad luck.

