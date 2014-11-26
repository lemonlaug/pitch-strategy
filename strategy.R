source("load_data.R")
library(mgvc)

strikeouts <- mutate(strikeouts,
                     px_last=as.numeric(px_last),
                     pz_last=as.numeric(pz_last),
                     pitch_type_last=factor(pitch_type_last))

#Model probability of swinging strike based on pitch type/location
model.formula <- swinging_k ~  pitch_type_last + s(px_last, pz_last, by=pitch_type_last)

ss.right <- strikeouts %>%
    filter(pitch_type_last %in% c('FF', 'SL', 'CU', 'CH') & stand_last=='R'
           & p_throws_last=='R')

overall <- gam(model.formula, data=ss.right, family="binomial")

summary(overall)

newd <- strikeouts %>%
    filter(pitch_type_last %in% c('FF', 'SL', 'CU', 'CH')) %>%
    with(., expand.grid(
    px_last=seq(min(px_last, na.rm=T), max(px_last, na.rm=T), .1),
    pz_last=seq(min(pz_last, na.rm=T), max(pz_last, na.rm=T), .1),
    pitch_type_last=factor(unique(pitch_type_last))))

overall.curve <-  cbind(predict(overall, newdata=newd, type="response"), newd)
names(overall.curve)[1] = 'prob_k'

ggplot(overall.curve, aes(x=px_last, y=pz_last, fill=prob_k)) + geom_tile() +
    facet_grid(. ~ pitch_type_last)
ggsave('plots/swinging_k_by_pitch_type.png')

#Now do a groupby with modeling for each pitch_type_setup?
#DPLYR IS AWESOME.
make.surface <- function(data, model.formula, overall.model, newd) {
    prob_k <- predict(gam(model.formula, data=data, family="binomial"), newdata=newd,
                      type="response")
    overall_prob <- predict(overall.model, newdata=newd, type="response")
    difference <- prob_k-overall_prob
    return(cbind(newd, prob_k, overall_prob, difference))
}

setup.models <- ss.right %>%
          filter(pitch_type_setup %in% c('FF', 'SL', 'CU', 'CH')) %>%
          group_by(pitch_type_setup) %>%
          do(make.surface(., model.formula, overall, newd)) %>%
              ungroup() %>% 
              mutate(pitch_type_setup = factor(pitch_type_setup))

summary(setup.models)
                     
ggplot(setup.models) + geom_tile(aes(x=px_last, y=pz_last, fill=prob_k)) +
    facet_grid(pitch_type_setup ~ pitch_type_last)
ggsave("plots/swinging_k_by_pitch_type_setup.png")

ggplot(setup.models) + geom_tile(aes(x=px_last, y=pz_last, fill=difference)) +
    facet_grid(pitch_type_setup ~ pitch_type_last) +
        scale_fill_gradient(low="red", high="green")
ggsave("plots/difference_swinging_k_by_pitch_type_setup.png")

#
# Called Strikes.
#

called.formula <- called_k ~  pitch_type_last + s(px_last, pz_last, by=pitch_type_last)
called.overall <- gam(called.formula, data=ss.right, family="binomial")
summary(called.overall)

called.overall.curve <- cbind(predict(called.overall, newdata=newd, type="response"), newd)
names(called.overall.curve)[1] = 'prob_k'

ggplot(called.overall.curve, aes(x=px_last, y=pz_last, fill=prob_k)) + geom_tile() +
    facet_grid(. ~ pitch_type_last)
ggsave('plots/called_k_by_pitch_type.png')

#Now do a groupby with modeling for each pitch_type_setup?
called.setup.models <- ss.right %>%
          filter(pitch_type_setup %in% c('FF', 'SL', 'CU', 'CH')) %>%
          group_by(pitch_type_setup) %>%
          do(make.surface(., called.formula, called.overall, newd)) %>%
              ungroup() %>% 
              mutate(pitch_type_setup = factor(pitch_type_setup))

ggplot(called.setup.models) + geom_tile(aes(x=px_last, y=pz_last, fill=prob_k)) +
    facet_grid(pitch_type_setup ~ pitch_type_last)
ggsave("plots/called_k_by_pitch_type_setup.png")

ggplot(called.setup.models) + geom_tile(aes(x=px_last, y=pz_last, fill=difference)) +
    facet_grid(pitch_type_setup ~ pitch_type_last) +
        scale_fill_gradient(low="red", high="green")
ggsave("plots/difference_called_k_by_pitch_type_setup.png")
