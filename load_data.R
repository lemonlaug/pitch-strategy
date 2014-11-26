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
           count, event, des, px, pz, stand, p_throws, pitcher, count) %>%
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
