library(splines)
library(arm)
library(pitchRx)
library(dplyr)
library(reshape2)

bins <- strikeouts %>%
    filter(speed_change > -20 & speed_change < 20 & !is.na(speed_change)) %>%
    group_by(pitcher_last, cut(speed_change, seq(-20, 20, 5))) %>%
    summarise(mean(swinging_k))
names(bins) <- c("pitcher_last", "speed_change", "prob_k")
ggplot(bins, aes(speed_change, prob_k, fill=pitcher_last)) +
    geom_bar(stat='identity', position="dodge")

bins <- strikeouts %>%
    filter(speed_change > -20 & speed_change < 20 & !is.na(speed_change)) %>%
    group_by(pitcher_last, cut(speed_change, seq(-20, 20, 5))) %>%
    summarise(mean(called_k))
names(bins) <- c("pitcher_last", "speed_change", "prob_k")
ggplot(bins, aes(speed_change, prob_k, fill=pitcher_last)) +
    geom_bar(stat='identity', position="dodge")


#Model change in speed effects.
#Swinging
speed.model <- strikeouts %>%
    bayesglm(swinging_k ~ factor(pitcher_last)*ns(speed_change, knots = seq(-20,20,5)), data=., family=binomial)

newdata <- expand.grid(speed_change = -15:15, pitcher_last=unique(strikeouts$pitcher_last))
preds <- predict(speed.model, newdata, type='response', se.fit=TRUE)

newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=speed_change, prob_k, colour=factor(pitcher_last))) +
    geom_smooth(aes(ymin = lcl, ymax=ucl)) +
    geom_hline(yintercept = mean(strikeouts$swinging_k), line_type=2, colour='black') +
    scale_colour_discrete(name='Pitcher') +
    xlab("Change in speed from setup pitch") +
    ylab("Probability of K") +
    ggtitle("Swinging Strikes")
p
ggsave('plots/speed_change_swinging.png')

#Called
speed.model <- strikeouts %>%
    bayesglm(called_k ~ factor(pitcher_last)*ns(speed_change, knots = seq(-20,20,5)),
             data=., family=binomial)

newdata <- expand.grid(speed_change = -15:15, pitcher_last=unique(strikeouts$pitcher_last))
preds <- predict(speed.model, newdata, type='response', se.fit=TRUE)

newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=speed_change, prob_k, colour=factor(pitcher_last))) +
    geom_smooth(aes(ymin = lcl, ymax=ucl)) +
#    geom_hline(yintercept = mean(strikeouts$called_k), line_type=2) +
    scale_colour_discrete(name='Pitcher') +
    xlab("Change in speed from setup pitch") +
    ylab("Probability of K") +
    ggtitle("Called Strikes")
p
ggsave('plots/speed_change_called.png')

#Check how often they get each kind of strikeout...
#About the same rate...
dcast(strikeouts, des_last ~ pitcher_last)
dcast(strikeouts, pitch_type_last ~ pitcher_last)


