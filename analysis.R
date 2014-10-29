library(splines)
library(arm)
library(pitchRx)
library(dplyr)
library(reshape2)

#Download data.
start = "2014-06-01"
end = "2014-10-01"

db <- src_sqlite("pitchfx.sqlite3", create=TRUE)
#pitches <- scrape(start=start, end=end, connect=db$con)

abs <- tbl(db, sql("SELECT * FROM atbat WHERE s in (2,3) and date > '2014-05-01'"))
pitches_ <- tbl(db, sql("SELECT * FROM pitch"))

abs <- inner_join(abs, pitches_, by=c("gameday_link", "num"))

#Mark the last pitch, and penultimate pitches.
z <- collect(abs)

y <- z %>%
     arrange(gameday_link, num, id) %>%
     group_by(gameday_link, num) %>%
     mutate(rk = rank(id), rrank=rank(id) - max(rk),
            lbl = plyr::mapvalues(rrank, c(0,-1), c('last', 'setup')),
            pitcher = ifelse(pitcher_name %in% c('James Shields', 'Madison Bumgarner'),
                             pitcher_name, 'Rest of League')) %>%
    filter(lbl %in% c('setup', 'last')) %>%
    select(gameday_link, num, pitch_type, lbl, start_speed,
           count, event, des, px, pz, stand, pitcher) %>%
    melt(id.vars=c('gameday_link', 'num', 'lbl')) %>%
    dcast(gameday_link + num  ~ variable + lbl)

pitchnames <- list('CH' = 'Change up',
                   'CU' = 'Curveball',
                   'FC' = 'Cutter',
                   'FF' = 'Four-seamer',
                   'FS' = 'Sinker',
                   'FT' = 'Two-seam',
                   'KC' = 'Knuckle Curve',
                   'KN' = 'Knuckle Ball',
                   'SI' = 'Sinker',
                   'SL' = 'Slider',
                   'SF' = 'Split-Finger')

#Independent of other variables, what pitches "set up" others best for swings and misses?
strikeouts <- y%>%
    mutate(swinging_k = des_last %in% c('Swinging Strike', 'Swinging Strke (Blocked)'),
           called_k = des_last=='Called Strike',
           speed_change = as.numeric(start_speed_last) - as.numeric(start_speed_setup),
           x_change = ifelse(stand_last=='L', -1, 1) * (as.numeric(px_last) - as.numeric(px_setup)),
           y_change = as.numeric(pz_last) - as.numeric(pz_setup))
       
        
#Model setup pitch effects.
pitch.model <- bayesglm(swinging_k ~ factor(pitch_type_last)*factor(pitch_type_setup), data=strikeouts, family = binomial)
interesting.pitches <- c('FF', 'FT', 'FC', 'SL', 'CU', 'CH', 'SI')
newdata <- with(strikeouts,
                   expand.grid(pitch_type_last = interesting.pitches,
                               pitch_type_setup = interesting.pitches ))
preds = predict(pitch.model, newdata, type='response', se.fit = TRUE)
newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=pitch_type_last, prob_k, ymax=ucl, ymin=lcl)) +
    geom_pointrange() +
    geom_hline(yintercept = mean(strikeouts$swinging_k), line_type=2, colour='red') +
    facet_grid(. ~ pitch_type_setup) + coord_flip()
p
ggsave('plots/pitch_selection.png')

#Model change in speed effects.
#Swinging
speed.model <- strikeouts %>%
    bayesglm(swinging_k ~ factor(pitcher_last)*ns(speed_change, knots = c(-20, -10, 0, 10, 20)), data=., family=binomial)
x
newdata <- expand.grid(speed_change = -20:20, pitcher_last=unique(strikeouts$pitcher_last))
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
    bayesglm(called_k ~ factor(pitcher_last)*ns(speed_change, knots = c(-20, -10, 0, 10, 20)),
             data=., family=binomial)

newdata <- expand.grid(speed_change = -20:20, pitcher_last=unique(strikeouts$pitcher_last))
preds <- predict(speed.model, newdata, type='response', se.fit=TRUE)

newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=speed_change, prob_k, colour=factor(pitcher_last))) +
    geom_smooth(aes(ymin = lcl, ymax=ucl)) +
    geom_hline(yintercept = mean(strikeouts$called_k), line_type=2) +
    scale_colour_discrete(name='Pitcher') +
    xlab("Change in speed from setup pitch") +
    ylab("Probability of K") +
    ggtitle("Called Strikes")
p
ggsave('plots/speed_change_called.png')

#What's up with the
dcast(strikeouts, pitcher_last ~ des_last)



