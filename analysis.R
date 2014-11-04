library(splines)
library(arm)
library(pitchRx)
library(dplyr)
library(reshape2)

#Download data.
start = "2014-07-01"
end = "2014-10-01"

db <- src_sqlite("pitchfx.sqlite3", create=FALSE)
#Uncomment to download data only needs to happen once.
#pitches <- scrape(start=start, end=end, connect=db$con)

#Select only the setup and strikeout pitches.
abs <- tbl(db, sql("SELECT * FROM atbat WHERE  date > '2014-03-01'"))
pitches_ <- tbl(db, sql("SELECT * FROM pitch"))

#Join on atbat info.
abs <- inner_join(abs, pitches_, by=c("gameday_link", "num"))

#Need to join pitches, with setup pitches.
z <- collect(abs) #Need to use rank, not implemented in sqlite.

y <- rbind_list(mutate(z, lbl='last'),
                mutate(z, lbl='setup')) %>%
     arrange(lbl, gameday_link, num, id) %>%
     group_by(lbl, gameday_link, num) %>%
     mutate(rk = rank(id),
            rrank=rank(id) - max(rk),
            rrank = ifelse(lbl=='setup', rrank+1, rrank)
            ) %>%
    filter(lbl %in% c('setup', 'last') & rk > 1 & rrank < 1) %>%
    select(gameday_link, num, rrank, pitch_type, lbl, start_speed,
           count, event, des, px, pz, stand, pitcher, count) %>%
    melt(id.vars=c('gameday_link', 'num', 'rrank', 'lbl')) %>%
    dcast(gameday_link + num + rrank  ~ variable + lbl) %>%
    filter(!is.na(event_setup))

#Independent of other variables, what pitches "set up" others best for swings and misses?
strikeouts <- y%>%
    mutate(swinging_k = des_last %in% c('Swinging Strike', 'Swinging Strike (Blocked)'),
           called_k = des_last=='Called Strike',
           speed_change = as.numeric(start_speed_last) - as.numeric(start_speed_setup),
           x_change = ifelse(stand_last=='L', -1, 1) * (as.numeric(px_last) - as.numeric(px_setup)),
           y_change = as.numeric(pz_last) - as.numeric(pz_setup))

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


