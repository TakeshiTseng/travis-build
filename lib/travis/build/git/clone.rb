require 'shellwords'

module Travis
  module Build
    class Git
      class Clone < Struct.new(:sh, :data)
        def apply
          if use_sparse_checkout?

            sh.fold 'git.checkout' do
              init_git_repo
              sh.cd dir
              config_sparse_checkout
              pull_git_repo
            end

          else
            sh.fold 'git.checkout' do
              clone_or_fetch
              sh.cd dir
              fetch_ref if fetch_ref?
              checkout
            end
          end

        end

        private

          def clone_or_fetch
            sh.if "! -d #{dir}/.git" do
              sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, retry: true
            end
            sh.else do
              sh.cmd "git -C #{dir} fetch origin", assert: true, retry: true
              sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
            end
          end

          def fetch_ref
            sh.cmd "git fetch origin +#{data.ref}:", assert: true, retry: true
          end

          def fetch_ref?
            !!data.ref
          end

          def checkout
            sh.cmd "git checkout -qf #{data.pull_request ? 'FETCH_HEAD' : data.commit}", timing: false
          end

          def clone_args
            args = "--depth=#{depth}"
            args << " --branch=#{branch}" unless data.ref
            args << " --quiet" if quiet?
            args
          end

          def init_git_repo
            sh.cmd "git init #{dir}"
            sh.cmd "git remote add origin #{data.source_url}"
          end

          def pull_git_repo
            sh.cmd "git pull origin #{clone_args}"
          end

          def config_sparse_checkout
            sh.cmd "git config core.sparseCheckout true"
            sparse_checkout_files.each do |scf|
              sh.file '.git/info/sparse-checkout', "#{scf}", append: true
            end
          end

          def depth
            config[:git][:depth].to_s.shellescape
          end

          def branch
            data.branch.shellescape
          end

          def quiet?
            config[:git][:quiet]
          end

          def dir
            data.slug
          end

          def use_sparse_checkout?
            config[:git][:sparse_checkout]
          end

          def sparse_checkout_files
            config[:git][:sparse_checkout_files]
          end

          def config
            data.config
          end
      end
    end
  end
end
