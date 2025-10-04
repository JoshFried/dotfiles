return {
    {
        "LeonHeidelbach/trailblazer.nvim",
        lazy = false,
        config = function()
            require('trailblazer').setup({
                mappings = {
                    nv = {
                        motions = {
                            new_trail_mark = '<A-;>',
                            peek_move_next_down = "<leader>tpd",
                            peek_move_previous_up = "<leader>tpu",
                            toggle_trail_mark_list = '<A-m>',

                        },
                        actions = {
                            delete_all_trail_marks = '<A-L>',
                            paste_at_last_trail_mark = '<A-p>',
                            paste_at_all_trail_marks = '<A-P>',
                            set_trail_mark_select_mode = '<A-t>',
                            switch_to_next_trail_mark_stack = '<A-.>',
                            switch_to_previous_trail_mark_stack = '<A-,>',
                            set_trail_mark_stack_sort_mode = '<A-s>',
                        },
                    }
                }
            })
        end
    }
}
