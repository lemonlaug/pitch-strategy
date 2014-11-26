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

###Model change in position.
##In-out
#Swinging
eye.model <- bayesglm(swinging_k ~ ns(x_change, knots = seq(-5, 5, 2.5)),
                                      data=strikeouts, family=binomial)

newdata <- expand.grid(x_change = -5:5)
preds <- predict(eye.model, newdata, type='response', se.fit=TRUE)
newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=x_change, prob_k)) +
    geom_smooth(aes(ymin = lcl, ymax=ucl)) +
    geom_hline(yintercept = mean(strikeouts$swinging_k), line_type=2, colour='red')
p
ggsave('plots/x_change_swinging.png')

#Called
eye.model <- bayesglm(called_k ~ ns(x_change, knots = seq(-5, 5, 2.5)),
                      data=strikeouts, family=binomial)

newdata <- expand.grid(x_change = -5:5)
preds <- predict(eye.model, newdata, type='response', se.fit=TRUE)
newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=x_change, prob_k)) +
    geom_smooth(aes(ymin = lcl, ymax=ucl)) +
    geom_hline(yintercept = mean(strikeouts$called_k), line_type=2, colour='red')
p
ggsave('plots/x_change_called.png')

##Hi lo
#Swinging
eye.model <- bayesglm(swinging_k ~ ns(y_change, knots = seq(-5, 5, 2.5)),
                                      data=strikeouts, family=binomial)

newdata <- expand.grid(y_change = -5:5)
preds <- predict(eye.model, newdata, type='response', se.fit=TRUE)
newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=y_change, prob_k)) +
    geom_smooth(aes(ymin = lcl, ymax=ucl)) +
    geom_hline(yintercept = mean(strikeouts$swinging_k), line_type=2, colour='red')
p
ggsave('plots/y_change_swinging.png')

#Called
eye.model <- bayesglm(called_k ~ ns(y_change, knots = seq(-5, 5, 2.5)),
                      data=strikeouts, family=binomial)

newdata <- expand.grid(y_change = -5:5)
preds <- predict(eye.model, newdata, type='response', se.fit=TRUE)
newdata$prob_k <- preds$fit
newdata$lcl <- pmax(0, preds$fit - 1.96*preds$se.fit)
newdata$ucl <- pmin(1, preds$fit + 1.96*preds$se.fit)

p <- newdata %>%
    ggplot(aes(x=y_change, prob_k)) +
    geom_smooth(aes(ymin = lcl, ymax=ucl)) +
    geom_hline(yintercept = mean(strikeouts$called_k), line_type=2, colour='red')
p
ggsave('plots/y_change_called.png')
