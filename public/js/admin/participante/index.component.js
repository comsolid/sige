$(function() {
    moment.lang('pt-br');
    function debounce(fn, delay) {
        var timeoutID = null
        return function() {
            clearTimeout(timeoutID)
            var args = arguments
            var that = this
            timeoutID = setTimeout(function() {
                fn.apply(that, args)
            }, delay)
        }
    }

    Vue.filter('fromNow', function (value) {
        if (!value) return '';
        value = value.toString();
        return moment(value, 'YYYY-MM-DD HH:mm:ss.SSSS').fromNow();
    });

    var jed = {};
    function installJed(Vue, options) {
        Vue.prototype.$t = function (text) {
            return _(text);
        }
    }
    jed.install = installJed;
    Vue.use(jed);

    var busca = {
        template: '#participante-busca',
        name: 'participante-busca',
        props: {
            isLoading: {
                type: Boolean,
                default: false
            }
        },
        data: function() {
            return {
                form: {
                    termo: '',
                    buscar_por: 'nome'
                }
            };
        },
        methods: {
            buscar: function() {
                this.$emit('buscar', this.form);
            }
        },
        watch: {
            'form.termo': debounce(function(newVal) {
                this.$emit('buscar', this.form);
            }, 500),
            'form.buscar_por': function () {
                this.$refs.termo.focus();
                this.$emit('buscar', this.form);
            }
        }
    };
    var item = {
        template: '#participante-item',
        name: 'participante-item',
        props: {
            item: {
                type: Object,
                required: true
            },
            index: {
                type: Number,
                required: true
            }
        },
        data: function () {
            return {
                button: {
                    text: '',
                    icon: ''
                },
                label: {
                    text: '',
                    kind: ''
                },
                box: {
                    kind: ''
                },
                isSaving: false
            };
        },
        mounted: function () {
            this.updateStatus();
        },
        methods: {
            updateStatus: function () {
                if (this.item.confirmado) {
                    this.label.text = 'Confirmado';
                    this.label.kind = 'label-success';
                    this.box.kind = 'box-success';
                    this.button.label = 'Desfazer confirmar';
                    this.button.icon = 'fa-ban';
                } else {
                    this.label.text = 'Não confirmado';
                    this.label.kind = 'label-danger';
                    this.box.kind = 'box-danger';
                    this.button.label = 'Confirmar';
                    this.button.icon = 'fa-check';
                }
            },
            changeStatus: function () {
                var vm = this;
                vm.isSaving = true;
                vm.$parent.$emit('changeStatus', vm.index, vm.item, function () {
                    vm.isSaving = false;
                });
            }
        },
        watch: {
            'item.confirmado': function (newValue, oldValue) {
                this.updateStatus();
            }
        }
    };
    var lista = {
        template: '#participante-lista',
        name: 'participante-lista',
        props: {
            lista: {
                type: Array,
                required: true
            }
        },
        components: {
            'participante-item': item
        }
    };

    var index = new Vue({
        el: '#participante-app',
        template: '#template-index',
        components: {
            'participante-busca': busca,
            'participante-lista': lista
        },
        data: {
            busca: {
                isLoading: false
            },
            lista: []
        },
        mounted: function() {
            this.buscar();
        },
        methods: {
            buscar: function(params) {
                var vm = this;
                vm.busca.isLoading = true;
                var promise = $.ajax({
                    url: '/admin/participante/ajax-buscar/',
                    type: 'POST',
                    data: $.extend({
                        format: 'json'
                    }, params)
                });
                promise.done(function(json) {
                    if (json.lista) {
                        vm.lista = json.lista;
                    }
                });
                promise.fail(function(jqXHR, textStatus, errorThrown) {
                    alertify.error(textStatus + ':' + errorThrown);
                });
                promise.always(function() {
                    vm.busca.isLoading = false;
                });
            },
            changeStatus: function (index, item, onFinished) {
                var vm = this;
                var url;
                if (item.confirmado) {
                    url = '/u/desfazer-confirmar/';
                } else {
                    url = '/u/confirmar/';
                }
                url += item.id;
                var params = {
        			format: 'json'
        		};
                $.getJSON(url, params, function(json) {
        			if (json.ok) {
        				alertify.success(json.msg);
                        vm.lista[index].confirmado = json.result.confirmado;
                        vm.lista[index].data_cadastro = json.result.data_cadastro;
                        vm.lista[index].data_confirmacao = json.result.data_confirmacao;
        			} else if (json.erro !== null) {
        				alertify.error(json.erro);
        			}
        		}).complete(function () {
        			onFinished();
        		});
            }
        }
    });
});
