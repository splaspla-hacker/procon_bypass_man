require "spec_helper"

describe ProconBypassMan::RemotePbmAction::RebootPbmAction do
  describe '#run!' do
    let(:action) { described_class.new(pbm_job_uuid: "a") }
    subject { action.run! }

    context 'エラーが起きないとき' do
      before do
        expect(action).to receive(:action_content)
      end

      it do
        expect(action).to receive(:be_processed)
        expect(action).not_to receive(:be_in_progress)
        expect(action).not_to receive(:be_failed)
        subject
      end
    end

    context 'エラーが起きるとき' do
      before do
        expect(action).to receive(:action_content) { raise }
      end

      it do
        expect(action).to receive(:be_processed)
        expect(action).to receive(:be_failed)
        expect(action).not_to receive(:be_in_progress)
        subject
      end

      it do
        expect(ProconBypassMan::SendErrorCommand).to receive(:execute)
        subject
      end
    end
  end
end
