ids = ['ERR908507', 'ERR908506', 'ERR908505']

ch_vl = Channel.value(ids)
ch_qu = Channel.of(ids)

//ch_vl.view()
//ch_qu.view()

list_vl = Channel.fromList(ids)
list_vl.view()