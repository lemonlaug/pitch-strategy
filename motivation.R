library(pitchRx)
start = "2014-10-29"
end = "2014-10-29"

pfx <- scrape(start=start, end=end)

abs <- inner_join(pfx$atbat, pfx$pitch, by=c("gameday_link", "num"))

final<- filter(abs, o==3, inning.x==9, inning_side.x=='bottom') %>%
    mutate(order = rank(id))


p <- ggplot(collect(final), aes(px, pz, colour=des)) +
    geom_point() +
    geom_text(aes(label=order),hjust=-1, vjust=-.5, show_guide=F) + 
    scale_colour_discrete(name='Pitch Outcome') +
    geom_hline(aes(yintercept=mean(final$sz_top))) +
    annotate("text", label="Top of Strike Zone", x=.2, y=mean(final$sz_top)*1.02) +
    xlab("") +
    ylab("") +
    ggtitle("Perez vs. Bumgarner")
p
ggsave("plots/perez_v_bumgarner.png")
