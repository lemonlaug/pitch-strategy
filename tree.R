library(party)
library(rattle)

outcomes <- list('Ball'='Ball',
                 'In play, no out'='In Play',
                 'Swinging Strike'='Swinging',
                 'In play, out(s)'='In Play',
                 'Foul'='Foul',
                 'Called Strike'='Called Strike',
                 'Ball In Dirt'='Ball',
                 'In play, run(s)'='In Play',
                 'Foul Tip'='Swinging',
                 "Swinging Strike (Blocked)"='Swinging',
                 'Foul (Runner Going)'='Foul',
                 'Hit By Pitch'='',
                 'Foul Bunt'='',
                 'Pitchout'='',
                 'Missed Bunt'='',
                 'Intent Ball'='Ball',
                 'Swinging Pitchout'='',
                 'Automatic Ball'='Ball'
                 )

model_data <- strikeouts %>%
    #Filter a few uninteresting outcomes.
    filter(!(des_last %in% c('Swinging Pitchout',
                             'Missed Bunt', 'Hit By Pitch', 'Ball In Dirt',
                             'Foul Bunt', 'Pitchout')) &
           !(des_setup %in% c('Intent Ball', 'Swinging Pitchout',
                             'Missed Bunt', 'Hit By Pitch', 'Ball In Dirt',
                             'Foul Bunt', 'Pitchout'))) %>%
    mutate(compress=plyr::mapvalues(des_last, names(outcomes), unlist(outcomes)))

    #Use a tree model to see what strategies are good.
swing_strategy <- ctree(factor(compress) ~ factor(pitch_type_last) +
                            factor(pitch_type_setup) +
                            I(as.numeric(px_last)) +
                            I(as.numeric(px_setup)) +
                            I(as.numeric(pz_setup)) +
                            I(as.numeric(pz_last)) +
                            I(as.numeric(start_speed_last)) +
                            I(as.numeric(start_speed_setup)) +
                            factor(stand_last) +
                            factor(des_setup) +
                            factor(count_last),
                        data = model_data,
                        controls = ctree_control(maxdepth = 4)
                        )

pdf("plots/swinging_tree.pdf", width=80, height=15)
plot(swing_strategy)
#     terminal_panel = node_terminal(swing_strategy))
dev.off()

probs <- tapply(treeresponse(swing_strategy), where(swing_strategy), unique)
p <- data.frame(matrix(unlist(probs), ncol=5, byrow=TRUE))[c(2,4),]
names(p) <- levels(factor(model_data$compress))
p$count <- c('1-2', '2-1')

plt <- ggplot(melt(p, id.vars=c('count')), aes(variable, value, fill=count)) +
    geom_bar(stat='identity', position='dodge') +
        ylab("Probability of Outcome") +
            xlab("Outcome") +
                ggtitle("Outcomes for Fastball")
        
plt
